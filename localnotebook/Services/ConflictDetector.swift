import Foundation
import CloudKit

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge(String)
}

final class ConflictDetector {
    
    private let mergeWindow: TimeInterval = 5 * 60
    
    func hasConflict(local: SyncMetadata, remote: [String: Int], modifiedAt: Date) -> Bool {
        let localClock = local.vectorClock as? [String: Int] ?? [:]
        
        if local.contentHash == remoteHash(modifiedAt: modifiedAt) {
            return false
        }
        
        let isConcurrent = !happensBefore(localClock, remote) && !happensBefore(remote, localClock)
        
        let timeDiff = abs(local.lastModified.timeIntervalSince(modifiedAt))
        let isWithinMergeWindow = timeDiff < mergeWindow
        
        return isConcurrent || isWithinMergeWindow
    }
    
    func resolve(local: Note, remote: CKRecord) -> ConflictResolution {
        let localModified = local.modifiedAt
        guard let remoteModified = remote["modifiedAt"] as? Date else {
            return .useLocal
        }
        
        if localModified > remoteModified {
            return .useLocal
        } else if remoteModified > localModified {
            return .useRemote
        }
        
        if let remoteContent = extractContent(from: remote) {
            let merged = mergeContent(local.content, remoteContent)
            return .merge(merged)
        }
        
        return .useRemote
    }
    
    private func happensBefore(_ clock1: [String: Int], _ clock2: [String: Int]) -> Bool {
        var atLeastOneLess = false
        
        for (device, time1) in clock1 {
            let time2 = clock2[device, default: 0]
            if time1 > time2 {
                return false
            }
            if time1 < time2 {
                atLeastOneLess = true
            }
        }
        
        for device in clock2.keys where clock1[device] == nil {
            atLeastOneLess = true
        }
        
        return atLeastOneLess
    }
    
    private func extractContent(from record: CKRecord) -> String? {
        guard let asset = record["encryptedContent"] as? CKAsset,
              let fileURL = asset.fileURL,
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func mergeContent(_ local: String, _ remote: String) -> String {
        let localLines = local.components(separatedBy: .newlines)
        let remoteLines = remote.components(separatedBy: .newlines)
        
        var merged: [String] = []
        var localIndex = 0
        var remoteIndex = 0
        
        while localIndex < localLines.count || remoteIndex < remoteLines.count {
            if localIndex < localLines.count {
                merged.append(localLines[localIndex])
                localIndex += 1
            }
            
            if remoteIndex < remoteLines.count {
                if remoteLines[remoteIndex] != localLines[safe: localIndex - 1] {
                    merged.append(remoteLines[remoteIndex])
                }
                remoteIndex += 1
            }
        }
        
        return merged.joined(separator: "\n")
    }
    
    private func remoteHash(modifiedAt: Date) -> Data? {
        return nil
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        guard index >= startIndex && index < endIndex else {
            return nil
        }
        return self[index]
    }
}

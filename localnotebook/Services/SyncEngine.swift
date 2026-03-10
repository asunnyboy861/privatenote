import Foundation
import CloudKit
import CryptoKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import IOKit
#endif

enum SyncEngineError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case cloudQuotaExceeded
    case syncFailed
    case conflictResolutionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "iCloud account not available. Please sign in to iCloud."
        case .networkUnavailable:
            return "Network unavailable. Changes will sync when online."
        case .cloudQuotaExceeded:
            return "iCloud storage quota exceeded."
        case .syncFailed:
            return "Sync failed. Will retry automatically."
        case .conflictResolutionFailed:
            return "Failed to resolve sync conflict."
        }
    }
}

protocol SyncEngineProtocol {
    func pushChanges() async throws
    func pullChanges() async throws
    func syncAll() async throws
    func isAvailable() -> Bool
}

final class SyncEngine: SyncEngineProtocol, ObservableObject {
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var lastSyncError: Error?
    
    private let container: CKContainer
    private let cryptoEngine: CryptoEngineProtocol
    private let keyManager: KeyManagerProtocol
    private let noteStore: NoteStoreProtocol
    private let conflictDetector: ConflictDetector
    private let syncQueue: SyncQueue
    
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    init(
        container: CKContainer = CKContainer(identifier: "iCloud.com.yourname.privernote"),
        cryptoEngine: CryptoEngineProtocol = CryptoEngine(),
        keyManager: KeyManagerProtocol = KeyManager(),
        noteStore: NoteStoreProtocol = NoteStore(),
        conflictDetector: ConflictDetector = ConflictDetector(),
        syncQueue: SyncQueue = SyncQueue.shared
    ) {
        self.container = container
        self.cryptoEngine = cryptoEngine
        self.keyManager = keyManager
        self.noteStore = noteStore
        self.conflictDetector = conflictDetector
        self.syncQueue = syncQueue
    }
    
    func isAvailable() -> Bool {
        var isAvailable = false
        let semaphore = DispatchSemaphore(value: 0)
        
        container.accountStatus { status, _ in
            isAvailable = (status == .available)
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5.0)
        return isAvailable
    }
    
    func pushChanges() async throws {
        guard isAvailable() else {
            throw SyncEngineError.notAuthenticated
        }
        
        let notes = try noteStore.fetchAllNotes()
        
        for note in notes {
            try await pushNote(note)
        }
    }
    
    func pullChanges() async throws {
        guard isAvailable() else {
            throw SyncEngineError.notAuthenticated
        }
        
        let query = CKQuery(recordType: "EncryptedNote", predicate: NSPredicate(value: true))
        
        var results: [CKRecord] = []
        
        do {
            let (recordResults, _) = try await database.records(matching: query)
            for (_, result) in recordResults {
                switch result {
                case .success(let record):
                    results.append(record)
                case .failure(let error):
                    print("Failed to fetch record: \(error)")
                }
            }
        } catch {
            print("Pull changes error: \(error)")
            throw SyncEngineError.syncFailed
        }
        
        for record in results {
            try await processRemoteRecord(record)
        }
    }
    
    func syncAll() async throws {
        await MainActor.run {
            isSyncing = true
            lastSyncError = nil
        }
        
        do {
            try await pullChanges()
            try await pushChanges()
            try await syncQueue.syncPendingOperations()
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                lastSyncError = error
                isSyncing = false
            }
            throw error
        }
    }
    
    private func pushNote(_ note: Note) async throws {
        let recordID = CKRecord.ID(recordName: note.id)
        
        guard let key = try? keyManager.retrieveKey(identifier: "masterKey") else {
            throw SyncEngineError.notAuthenticated
        }
        
        let encryptedContent: Data
        if let existingEncrypted = note.encryptedContent {
            encryptedContent = existingEncrypted
        } else {
            encryptedContent = try cryptoEngine.encrypt(note.content, with: key)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(note.id).dat")
        try encryptedContent.write(to: tempURL)
        let asset = CKAsset(fileURL: tempURL)
        
        let record = CKRecord(recordType: "EncryptedNote", recordID: recordID)
        record.setValue(asset, forKey: "encryptedContent")
        record.setValue(note.title, forKey: "title")
        record.setValue(note.tags, forKey: "tags")
        record.setValue(note.isPinned, forKey: "isPinned")
        record.setValue(note.isFavorite, forKey: "isFavorite")
        record.setValue(note.modifiedAt, forKey: "modifiedAt")
        
        if var vectorClock = note.syncMetadata?.vectorClock {
            let deviceID = getDeviceID()
            vectorClock[deviceID, default: 0] += 1
            record.setValue(serializeVectorClock(vectorClock), forKey: "vectorClock")
        } else {
            let deviceID = getDeviceID()
            record.setValue(serializeVectorClock([deviceID: 1]), forKey: "vectorClock")
        }
        
        do {
            _ = try await database.save(record)
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            try await syncQueue.enqueue(.update(
                noteID: note.id,
                content: note.content,
                metadata: note.syncMetadata
            ))
            throw SyncEngineError.syncFailed
        }
    }
    
    private func processRemoteRecord(_ remoteRecord: CKRecord) async throws {
        let noteID = remoteRecord.recordID.recordName
        
        guard let encryptedAsset = remoteRecord.value(forKey: "encryptedContent") as? CKAsset,
              let fileURL = encryptedAsset.fileURL,
              let encryptedData = try? Data(contentsOf: fileURL),
              let title = remoteRecord.value(forKey: "title") as? String,
              let modifiedAt = remoteRecord.value(forKey: "modifiedAt") as? Date else {
            return
        }
        
        let remoteVectorClock = deserializeVectorClock(remoteRecord.value(forKey: "vectorClock") as? String ?? "")
        
        let localNote = try? noteStore.fetchNote(by: noteID)
        
        if let local = localNote,
           let localMetadata = local.syncMetadata,
           conflictDetector.hasConflict(local: localMetadata, remote: remoteVectorClock, modifiedAt: modifiedAt) {
            try await handleConflict(local: local, remote: remoteRecord, remoteVectorClock: remoteVectorClock)
            return
        }
        
        guard let key = try? keyManager.retrieveKey(identifier: "masterKey") else {
            return
        }
        
        let decryptedContent = try cryptoEngine.decrypt(encryptedData, with: key)
        
        let tags = remoteRecord.value(forKey: "tags") as? [String] ?? []
        let isPinned = remoteRecord.value(forKey: "isPinned") as? Bool ?? false
        let isFavorite = remoteRecord.value(forKey: "isFavorite") as? Bool ?? false
        
        let contentHash = Data(SHA256.hash(data: encryptedData).compactMap { $0 })
        
        let note = Note(
            id: noteID,
            title: title,
            content: decryptedContent,
            encryptedContent: encryptedData,
            tags: tags,
            isPinned: isPinned,
            isFavorite: isFavorite,
            createdAt: localNote?.createdAt ?? modifiedAt,
            modifiedAt: modifiedAt,
            syncMetadata: SyncMetadata(
                recordID: noteID,
                vectorClock: remoteVectorClock,
                lastModified: modifiedAt,
                contentHash: contentHash,
                deviceId: getDeviceID()
            )
        )
        
        try noteStore.save(note)
    }
    
    private func handleConflict(local: Note, remote: CKRecord, remoteVectorClock: [String: Int]) async throws {
        let resolution = conflictDetector.resolve(local: local, remote: remote)
        
        switch resolution {
        case .useLocal:
            try await pushNote(local)
        case .useRemote:
            try await processRemoteRecord(remote)
        case .merge(let mergedContent):
            var mergedNote = local
            mergedNote.content = mergedContent
            mergedNote.modifiedAt = Date()
            try noteStore.save(mergedNote)
            try await pushNote(mergedNote)
        }
    }
    
    private func serializeVectorClock(_ clock: [String: Int]) -> String {
        let pairs = clock.map { "\($0.key):\($0.value)" }
        return pairs.joined(separator: ",")
    }
    
    private func deserializeVectorClock(_ string: String) -> [String: Int] {
        guard !string.isEmpty else { return [:] }
        
        var clock: [String: Int] = [:]
        let pairs = string.components(separatedBy: ",")
        
        for pair in pairs {
            let components = pair.components(separatedBy: ":")
            if components.count == 2, let value = Int(components[1]) {
                clock[components[0]] = value
            }
        }
        
        return clock
    }
    
    private func getDeviceID() -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #elseif os(macOS)
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if platformExpert != 0 {
            defer { IOObjectRelease(platformExpert) }
            if let serialNumber = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String {
                return serialNumber
            }
        }
        return "unknown"
        #else
        return "unknown"
        #endif
    }
}

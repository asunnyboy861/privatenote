import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var content: String
    var encryptedContent: Data?
    var tags: [String]
    var isPinned: Bool
    var isFavorite: Bool
    var createdAt: Date
    var modifiedAt: Date
    var syncMetadata: SyncMetadata?
    
    init(
        id: String = UUID().uuidString,
        title: String = "",
        content: String = "",
        encryptedContent: Data? = nil,
        tags: [String] = [],
        isPinned: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        syncMetadata: SyncMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.encryptedContent = encryptedContent
        self.tags = tags
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.syncMetadata = syncMetadata
    }
    
    var preview: String {
        if content.isEmpty {
            return "No content"
        }
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }
    
    var wordCount: Int {
        return content.split(separator: " ").count
    }
}

struct SyncMetadata: Codable, Equatable {
    let recordID: String
    var vectorClock: [String: Int]
    let lastModified: Date
    let contentHash: Data
    let deviceId: String
    
    func happensBefore(_ other: SyncMetadata) -> Bool {
        for (device, seq) in vectorClock {
            if (other.vectorClock[device] ?? 0) < seq {
                return false
            }
        }
        return true
    }
    
    func concurrentWith(_ other: SyncMetadata) -> Bool {
        return !happensBefore(other) && !other.happensBefore(self)
    }
    
    static func merge(_ a: SyncMetadata, _ b: SyncMetadata) -> [String: Int] {
        var merged = a.vectorClock
        for (device, seq) in b.vectorClock {
            merged[device] = max(merged[device] ?? 0, seq)
        }
        return merged
    }
}

import Foundation
import CloudKit

enum SyncOperation: Codable {
    case create(noteID: String, content: String, metadata: SyncMetadata?)
    case update(noteID: String, content: String, metadata: SyncMetadata?)
    case delete(noteID: String)
    
    var noteID: String {
        switch self {
        case .create(let id, _, _):
            return id
        case .update(let id, _, _):
            return id
        case .delete(let id):
            return id
        }
    }
}

actor SyncQueueActor {
    private var operations: [SyncOperation] = []
    private var isSyncing = false
    
    func getOperations() -> [SyncOperation] {
        return operations
    }
    
    func addOperation(_ operation: SyncOperation) {
        operations.append(operation)
    }
    
    func removeOperations(for noteID: String) {
        operations.removeAll { $0.noteID == noteID }
    }
    
    func clear() {
        operations.removeAll()
    }
    
    func isSyncingStatus() -> Bool {
        return isSyncing
    }
    
    func setSyncing(_ syncing: Bool) {
        isSyncing = syncing
    }
    
    func save(to path: URL, encoder: JSONEncoder) throws {
        let data = try encoder.encode(operations)
        try data.write(to: path)
    }
    
    func load(from path: URL, decoder: JSONDecoder) throws {
        let data = try Data(contentsOf: path)
        operations = try decoder.decode([SyncOperation].self, from: data)
    }
}

final class SyncQueue {
    
    static let shared = SyncQueue()
    
    private let queuePath: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queueActor = SyncQueueActor()
    
    private var isSyncing = false
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        queuePath = documentsPath.appendingPathComponent("sync_queue.json")
        Task {
            await loadOperations()
        }
    }
    
    func enqueue(_ operation: SyncOperation) async throws {
        await queueActor.addOperation(operation)
        try await saveOperations()
        
        print("Enqueued sync operation: \(operation.noteID)")
    }
    
    func syncPendingOperations() async throws {
        let isCurrentlySyncing = await queueActor.isSyncingStatus()
        let operations = await queueActor.getOperations()
        
        guard !isCurrentlySyncing && !operations.isEmpty else {
            return
        }
        
        await queueActor.setSyncing(true)
        
        var failedOperations: [SyncOperation] = []
        
        for operation in operations {
            do {
                try await executeOperation(operation)
                await queueActor.removeOperations(for: operation.noteID)
            } catch {
                print("Failed to sync operation: \(error)")
                failedOperations.append(operation)
            }
        }
        
        try await saveOperations()
        await queueActor.setSyncing(false)
        
        if !failedOperations.isEmpty {
            throw SyncEngineError.syncFailed
        }
    }
    
    func clearQueue() async throws {
        await queueActor.clear()
        try await saveOperations()
    }
    
    private func executeOperation(_ operation: SyncOperation) async throws {
        switch operation {
        case .create, .update:
            try await performUpsert(operation)
        case .delete:
            try await performDelete(operation)
        }
    }
    
    private func performUpsert(_ operation: SyncOperation) async throws {
        let container = CKContainer(identifier: "iCloud.com.yourname.privernote")
        
        // Check account status
        let status = try await container.accountStatus()
        guard status == .available else {
            throw SyncEngineError.notAuthenticated
        }
        
        let database = container.privateCloudDatabase
        
        switch operation {
        case .create(let noteID, let content, _),
             .update(let noteID, let content, _):
            let recordID = CKRecord.ID(recordName: noteID)
            let record = CKRecord(recordType: "EncryptedNote", recordID: recordID)
            
            if let data = content.data(using: .utf8) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(noteID).dat")
                try data.write(to: tempURL)
                let asset = CKAsset(fileURL: tempURL)
                record.setValue(asset, forKey: "encryptedContent")
            }
            
            _ = try await database.save(record)
            
        case .delete:
            break
        }
    }
    
    private func performDelete(_ operation: SyncOperation) async throws {
        let container = CKContainer(identifier: "iCloud.com.yourname.privernote")
        
        // Check account status
        let status = try await container.accountStatus()
        guard status == .available else {
            throw SyncEngineError.notAuthenticated
        }
        
        let database = container.privateCloudDatabase
        
        switch operation {
        case .delete(let noteID):
            let recordID = CKRecord.ID(recordName: noteID)
            try? await database.deleteRecord(withID: recordID)
            
        default:
            break
        }
    }
    
    private func saveOperations() async throws {
        try await queueActor.save(to: queuePath, encoder: encoder)
    }
    
    private func loadOperations() async {
        guard FileManager.default.fileExists(atPath: queuePath.path) else {
            return
        }
        
        do {
            try await queueActor.load(from: queuePath, decoder: decoder)
        } catch {
            print("Failed to load sync queue: \(error)")
        }
    }
    
    var pendingCount: Int {
        get async {
            return await queueActor.getOperations().count
        }
    }
}

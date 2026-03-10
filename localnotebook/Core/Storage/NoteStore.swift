import Foundation
import CoreData

enum NoteStoreError: LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case migrationFailed
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save the note."
        case .fetchFailed:
            return "Failed to fetch notes."
        case .deleteFailed:
            return "Failed to delete the note."
        case .migrationFailed:
            return "Failed to migrate data."
        case .dataCorrupted:
            return "Data is corrupted."
        }
    }
}

protocol NoteStoreProtocol {
    func save(_ note: Note) throws
    func fetchAllNotes() throws -> [Note]
    func fetchNote(by id: String) throws -> Note?
    func delete(_ note: Note) throws
    func deleteAllNotes() throws
}

final class NoteStore: NoteStoreProtocol {
    
    private let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PrivaNote")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save(_ note: Note) throws {
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        request.predicate = NSPredicate(format: "id == %@", note.id)
        request.fetchLimit = 1
        
        let entity: NoteEntity
        if let existing = try? context.fetch(request).first {
            entity = existing
        } else {
            entity = NoteEntity(context: context)
            entity.id = note.id
        }
        
        entity.title = note.title
        entity.content = note.content
        entity.encryptedContent = note.encryptedContent
        entity.tags = note.tags as NSArray
        entity.isPinned = note.isPinned
        entity.isFavorite = note.isFavorite
        entity.createdAt = note.createdAt
        entity.modifiedAt = note.modifiedAt
        
        do {
            try context.save()
        } catch {
            throw NoteStoreError.saveFailed
        }
    }
    
    func fetchAllNotes() throws -> [Note] {
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "isPinned", ascending: false),
            NSSortDescriptor(key: "modifiedAt", ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entityToNote($0) }
        } catch {
            throw NoteStoreError.fetchFailed
        }
    }
    
    func fetchNote(by id: String) throws -> Note? {
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            return entities.first.flatMap { entityToNote($0) }
        } catch {
            throw NoteStoreError.fetchFailed
        }
    }
    
    func delete(_ note: Note) throws {
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
        request.predicate = NSPredicate(format: "id == %@", note.id)
        
        do {
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
            try context.save()
        } catch {
            throw NoteStoreError.deleteFailed
        }
    }
    
    func deleteAllNotes() throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            throw NoteStoreError.deleteFailed
        }
    }
    
    private func entityToNote(_ entity: NoteEntity) -> Note? {
        guard let id = entity.id,
              let createdAt = entity.createdAt,
              let modifiedAt = entity.modifiedAt else {
            return nil
        }
        
        return Note(
            id: id,
            title: entity.title ?? "",
            content: entity.content ?? "",
            encryptedContent: entity.encryptedContent,
            tags: entity.tags as? [String] ?? [],
            isPinned: entity.isPinned,
            isFavorite: entity.isFavorite,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

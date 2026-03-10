import Foundation
import CoreData

@objc(NoteEntity)
public class NoteEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var encryptedContent: Data?
    @NSManaged public var tags: NSArray?
    @NSManaged public var isPinned: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
}

extension NoteEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        return NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }
}

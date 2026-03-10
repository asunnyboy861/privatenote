import XCTest
@testable import localnotebook

final class NoteRepositoryTests: XCTestCase {
    var repository: NoteRepository!
    var inMemoryStore: NoteStore!
    
    override func setUp() {
        super.setUp()
        inMemoryStore = NoteStore(inMemory: true)
        repository = NoteRepository(store: inMemoryStore)
    }
    
    override func tearDown() {
        repository = nil
        inMemoryStore = nil
        super.tearDown()
    }
    
    func testCreateNote() throws {
        let note = try repository.create(
            title: "Test Note",
            content: "Test Content",
            tags: ["test", "swift"]
        )
        
        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Test Content")
        XCTAssertEqual(note.tags, ["test", "swift"])
    }
    
    func testGetNote() throws {
        let createdNote = try repository.create(
            title: "Test",
            content: "Content"
        )
        
        let retrievedNote = try repository.get(id: createdNote.id)
        
        XCTAssertNotNil(retrievedNote)
        XCTAssertEqual(retrievedNote?.id, createdNote.id)
    }
    
    func testGetAllNotes() throws {
        _ = try repository.create(title: "Note 1", content: "Content 1")
        _ = try repository.create(title: "Note 2", content: "Content 2")
        _ = try repository.create(title: "Note 3", content: "Content 3")
        
        let notes = try repository.getAll()
        
        XCTAssertEqual(notes.count, 3)
    }
    
    func testUpdateNote() throws {
        let note = try repository.create(title: "Original", content: "Original Content")
        
        var updatedNote = note
        updatedNote.title = "Updated"
        updatedNote.content = "Updated Content"
        
        try repository.update(updatedNote)
        
        let retrieved = try repository.get(id: note.id)
        
        XCTAssertEqual(retrieved?.title, "Updated")
        XCTAssertEqual(retrieved?.content, "Updated Content")
    }
    
    func testDeleteNote() throws {
        let note = try repository.create(title: "To Delete", content: "Content")
        
        try repository.delete(id: note.id)
        
        let retrieved = try repository.get(id: note.id)
        XCTAssertNil(retrieved)
    }
    
    func testSearchNotes() throws {
        _ = try repository.create(title: "Swift Programming", content: "Learn Swift", tags: ["programming"])
        _ = try repository.create(title: "Cooking Recipes", content: "Delicious food", tags: ["cooking"])
        _ = try repository.create(title: "SwiftUI Tutorial", content: "Build apps with SwiftUI", tags: ["programming", "swift"])
        
        let swiftNotes = try repository.search(query: "Swift")
        XCTAssertEqual(swiftNotes.count, 2)
        
        let programmingNotes = try repository.search(query: "programming")
        XCTAssertEqual(programmingNotes.count, 2)
    }
}

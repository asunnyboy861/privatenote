import Foundation

protocol NoteRepositoryProtocol {
    func create(title: String, content: String, tags: [String]) throws -> Note
    func update(_ note: Note) throws
    func delete(id: String) throws
    func get(id: String) throws -> Note?
    func getAll() throws -> [Note]
    func search(query: String) throws -> [Note]
}

final class NoteRepository: NoteRepositoryProtocol {
    
    private let store: NoteStoreProtocol
    private let cryptoEngine: CryptoEngineProtocol
    private let keyManager: KeyManagerProtocol
    
    init(
        store: NoteStoreProtocol = NoteStore(),
        cryptoEngine: CryptoEngineProtocol = CryptoEngine(),
        keyManager: KeyManagerProtocol = KeyManager()
    ) {
        self.store = store
        self.cryptoEngine = cryptoEngine
        self.keyManager = keyManager
    }
    
    func create(title: String, content: String, tags: [String] = []) throws -> Note {
        let note = Note(
            title: title,
            content: content,
            tags: tags
        )
        
        try store.save(note)
        return note
    }
    
    func update(_ note: Note) throws {
        var updatedNote = note
        updatedNote.modifiedAt = Date()
        try store.save(updatedNote)
    }
    
    func delete(id: String) throws {
        guard let note = try get(id: id) else {
            return
        }
        try store.delete(note)
    }
    
    func get(id: String) throws -> Note? {
        return try store.fetchNote(by: id)
    }
    
    func getAll() throws -> [Note] {
        return try store.fetchAllNotes()
    }
    
    func search(query: String) throws -> [Note] {
        let allNotes = try getAll()
        
        if query.isEmpty {
            return allNotes
        }
        
        let lowercasedQuery = query.lowercased()
        return allNotes.filter { note in
            note.title.lowercased().contains(lowercasedQuery) ||
            note.content.lowercased().contains(lowercasedQuery) ||
            note.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
}

import Foundation

enum SmartFolderRule: Codable {
    case containsText(String)
    case hasTags([String])
    case createdAfter(Date)
    case createdBefore(Date)
    case modifiedAfter(Date)
    case modifiedBefore(Date)
    case isPinned
    case isFavorite
    case hasMinimumWordCount(Int)
}

struct SmartFolder: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String
    var rules: [SmartFolderRule]
    var matchMode: MatchMode
    
    enum MatchMode: Codable {
        case all
        case any
    }
    
    init(id: String = UUID().uuidString, name: String, icon: String = "folder.fill", rules: [SmartFolderRule] = [], matchMode: MatchMode = .all) {
        self.id = id
        self.name = name
        self.icon = icon
        self.rules = rules
        self.matchMode = matchMode
    }
}

enum SmartFolderError: LocalizedError {
    case noRules
    case folderNotFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .noRules:
            return "Smart folder must have at least one rule."
        case .folderNotFound:
            return "Smart folder not found."
        case .saveFailed:
            return "Failed to save smart folder."
        }
    }
}

protocol SmartFolderServiceProtocol {
    func createFolder(_ folder: SmartFolder) throws
    func updateFolder(_ folder: SmartFolder) throws
    func deleteFolder(id: String) throws
    func getAllFolders() throws -> [SmartFolder]
    func getNotes(in folder: SmartFolder) throws -> [Note]
}

final class SmartFolderService: SmartFolderServiceProtocol {
    
    private let noteRepository: NoteRepositoryProtocol
    private let searchService: SearchServiceProtocol
    private let storageKey = "smartFolders"
    
    init(
        noteRepository: NoteRepositoryProtocol = NoteRepository(),
        searchService: SearchServiceProtocol = SearchService()
    ) {
        self.noteRepository = noteRepository
        self.searchService = searchService
    }
    
    func createFolder(_ folder: SmartFolder) throws {
        guard !folder.rules.isEmpty else {
            throw SmartFolderError.noRules
        }
        
        var folders = try getAllFolders()
        folders.append(folder)
        try saveFolders(folders)
    }
    
    func updateFolder(_ folder: SmartFolder) throws {
        guard !folder.rules.isEmpty else {
            throw SmartFolderError.noRules
        }
        
        var folders = try getAllFolders()
        
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else {
            throw SmartFolderError.folderNotFound
        }
        
        folders[index] = folder
        try saveFolders(folders)
    }
    
    func deleteFolder(id: String) throws {
        var folders = try getAllFolders()
        folders.removeAll { $0.id == id }
        try saveFolders(folders)
    }
    
    func getAllFolders() throws -> [SmartFolder] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([SmartFolder].self, from: data)
        } catch {
            return []
        }
    }
    
    func getNotes(in folder: SmartFolder) throws -> [Note] {
        let allNotes = try noteRepository.getAll()
        
        return allNotes.filter { note in
            matchesFolder(note, folder)
        }
    }
    
    private func matchesFolder(_ note: Note, _ folder: SmartFolder) -> Bool {
        let results = folder.rules.map { rule in
            matchesRule(note, rule)
        }
        
        switch folder.matchMode {
        case .all:
            return results.allSatisfy { $0 }
        case .any:
            return results.contains { $0 }
        }
    }
    
    private func matchesRule(_ note: Note, _ rule: SmartFolderRule) -> Bool {
        switch rule {
        case .containsText(let text):
            return note.title.localizedCaseInsensitiveContains(text) ||
                   note.content.localizedCaseInsensitiveContains(text)
            
        case .hasTags(let tags):
            return tags.allSatisfy { tag in
                note.tags.contains(tag)
            }
            
        case .createdAfter(let date):
            return note.createdAt > date
            
        case .createdBefore(let date):
            return note.createdAt < date
            
        case .modifiedAfter(let date):
            return note.modifiedAt > date
            
        case .modifiedBefore(let date):
            return note.modifiedAt < date
            
        case .isPinned:
            return note.isPinned
            
        case .isFavorite:
            return note.isFavorite
            
        case .hasMinimumWordCount(let count):
            let wordCount = note.content.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }.count
            return wordCount >= count
        }
    }
    
    private func saveFolders(_ folders: [SmartFolder]) throws {
        do {
            let data = try JSONEncoder().encode(folders)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            throw SmartFolderError.saveFailed
        }
    }
}

extension SmartFolder {
    static let presets: [SmartFolder] = [
        SmartFolder(
            name: "Recent Notes",
            icon: "clock.fill",
            rules: [.modifiedAfter(Calendar.current.date(byAdding: .day, value: -7, to: Date())!)],
            matchMode: .all
        ),
        SmartFolder(
            name: "Pinned Notes",
            icon: "pin.fill",
            rules: [.isPinned],
            matchMode: .all
        ),
        SmartFolder(
            name: "Favorites",
            icon: "star.fill",
            rules: [.isFavorite],
            matchMode: .all
        ),
        SmartFolder(
            name: "Long Notes",
            icon: "doc.text.fill",
            rules: [.hasMinimumWordCount(500)],
            matchMode: .all
        ),
        SmartFolder(
            name: "Work",
            icon: "briefcase.fill",
            rules: [.hasTags(["work", "project"])],
            matchMode: .any
        )
    ]
}

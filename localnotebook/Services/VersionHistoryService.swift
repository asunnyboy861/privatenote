import Foundation

struct NoteVersion: Identifiable, Codable {
    let id: String
    let noteID: String
    let content: String
    let title: String
    let createdAt: Date
    let versionNumber: Int
    let changeSummary: String?
    
    init(
        id: String = UUID().uuidString,
        noteID: String,
        content: String,
        title: String,
        createdAt: Date = Date(),
        versionNumber: Int,
        changeSummary: String? = nil
    ) {
        self.id = id
        self.noteID = noteID
        self.content = content
        self.title = title
        self.createdAt = createdAt
        self.versionNumber = versionNumber
        self.changeSummary = changeSummary
    }
}

enum VersionHistoryError: LocalizedError {
    case saveFailed
    case notFound
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save version."
        case .notFound:
            return "Version not found."
        case .restoreFailed:
            return "Failed to restore version."
        }
    }
}

protocol VersionHistoryServiceProtocol {
    func saveVersion(note: Note, changeSummary: String?) throws
    func getVersions(noteID: String) throws -> [NoteVersion]
    func getVersion(versionID: String) throws -> NoteVersion
    func restoreVersion(_ version: NoteVersion) throws
    func deleteOldVersions(noteID: String, keepLast: Int) throws
}

final class VersionHistoryService: VersionHistoryServiceProtocol {
    
    private let noteRepository: NoteRepositoryProtocol
    private let cryptoEngine: CryptoEngineProtocol
    private let keyManager: KeyManagerProtocol
    
    private let maxVersionsPerNote = 50
    private let autoSaveInterval: TimeInterval = 5 * 60
    
    init(
        noteRepository: NoteRepositoryProtocol = NoteRepository(),
        cryptoEngine: CryptoEngineProtocol = CryptoEngine(),
        keyManager: KeyManagerProtocol = KeyManager()
    ) {
        self.noteRepository = noteRepository
        self.cryptoEngine = cryptoEngine
        self.keyManager = keyManager
    }
    
    func saveVersion(note: Note, changeSummary: String?) throws {
        let versions = try getVersions(noteID: note.id)
        let nextVersionNumber = (versions.last?.versionNumber ?? 0) + 1
        
        let version = NoteVersion(
            noteID: note.id,
            content: note.content,
            title: note.title,
            versionNumber: nextVersionNumber,
            changeSummary: changeSummary
        )
        
        try saveVersionToStorage(version)
        
        if versions.count >= maxVersionsPerNote {
            try deleteOldVersions(noteID: note.id, keepLast: maxVersionsPerNote)
        }
    }
    
    func getVersions(noteID: String) throws -> [NoteVersion] {
        let key = "versions_\(noteID)"
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([NoteVersion].self, from: data)
        } catch {
            return []
        }
    }
    
    func getVersion(versionID: String) throws -> NoteVersion {
        let allVersions = try getAllVersions()
        
        guard let version = allVersions.first(where: { $0.id == versionID }) else {
            throw VersionHistoryError.notFound
        }
        
        return version
    }
    
    func restoreVersion(_ version: NoteVersion) throws {
        let note = try noteRepository.getById(version.noteID)
        
        var restoredNote = note
        restoredNote.content = version.content
        restoredNote.title = version.title
        restoredNote.modifiedAt = Date()
        
        try noteRepository.update(restoredNote)
        
        try saveVersion(
            note: restoredNote,
            changeSummary: "Restored from version \(version.versionNumber)"
        )
    }
    
    func deleteOldVersions(noteID: String, keepLast: Int) throws {
        var versions = try getVersions(noteID: noteID)
        
        guard versions.count > keepLast else {
            return
        }
        
        versions.sort { $0.createdAt > $1.createdAt }
        versions = Array(versions.prefix(keepLast))
        
        try saveVersionsToStorage(versions, noteID: noteID)
    }
    
    func deleteAllVersions(noteID: String) throws {
        let key = "versions_\(noteID)"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    private func saveVersionToStorage(_ version: NoteVersion) throws {
        var versions = try getVersions(noteID: version.noteID)
        versions.append(version)
        try saveVersionsToStorage(versions, noteID: version.noteID)
    }
    
    private func saveVersionsToStorage(_ versions: [NoteVersion], noteID: String) throws {
        do {
            let data = try JSONEncoder().encode(versions)
            UserDefaults.standard.set(data, forKey: "versions_\(noteID)")
        } catch {
            throw VersionHistoryError.saveFailed
        }
    }
    
    private func getAllVersions() throws -> [NoteVersion] {
        var allVersions: [NoteVersion] = []
        
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix("versions_") {
            if let data = UserDefaults.standard.data(forKey: key),
               let versions = try? JSONDecoder().decode([NoteVersion].self, from: data) {
                allVersions.append(contentsOf: versions)
            }
        }
        
        return allVersions
    }
}

extension NoteRepositoryProtocol {
    func getById(_ id: String) throws -> Note {
        let allNotes = try getAll()
        guard let note = allNotes.first(where: { $0.id == id }) else {
            throw VersionHistoryError.notFound
        }
        return note
    }
}

class VersionHistoryManager: ObservableObject {
    @Published var versions: [NoteVersion] = []
    @Published var selectedVersion: NoteVersion?
    @Published var isShowingDiff = false
    
    private let service: VersionHistoryServiceProtocol
    
    init(service: VersionHistoryServiceProtocol = VersionHistoryService()) {
        self.service = service
    }
    
    func loadVersions(for noteID: String) {
        do {
            versions = try service.getVersions(noteID: noteID)
        } catch {
            print("Failed to load versions: \(error)")
        }
    }
    
    func saveVersion(note: Note, changeSummary: String? = nil) {
        do {
            try service.saveVersion(note: note, changeSummary: changeSummary)
            loadVersions(for: note.id)
        } catch {
            print("Failed to save version: \(error)")
        }
    }
    
    func restoreVersion(_ version: NoteVersion) {
        do {
            try service.restoreVersion(version)
            loadVersions(for: version.noteID)
        } catch {
            print("Failed to restore version: \(error)")
        }
    }
    
    func getDiff(oldVersion: NoteVersion, newVersion: NoteVersion) -> String {
        let oldLines = oldVersion.content.components(separatedBy: .newlines)
        let newLines = newVersion.content.components(separatedBy: .newlines)
        
        var diff = ""
        
        for (index, line) in newLines.enumerated() {
            if index >= oldLines.count {
                diff += "+ \(line)\n"
            } else if line != oldLines[index] {
                diff += "- \(oldLines[index])\n"
                diff += "+ \(line)\n"
            }
        }
        
        return diff
    }
}

import Foundation

enum ImportFormat {
    case markdown
    case plainText
    case fsNotes
    case notesnook
    
    static func detectFormat(from url: URL) -> ImportFormat? {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "md", "markdown":
            return .markdown
        case "txt":
            return .plainText
        case "fsnotes":
            return .fsNotes
        case "notesnook":
            return .notesnook
        default:
            return nil
        }
    }
}

enum ImportError: LocalizedError {
    case invalidFormat
    case fileNotFound
    case parseFailed
    case unsupportedEncoding
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid file format. Please select a valid Markdown or Text file."
        case .fileNotFound:
            return "File not found. Please check the file path."
        case .parseFailed:
            return "Failed to parse file content."
        case .unsupportedEncoding:
            return "Unsupported file encoding. Please use UTF-8."
        }
    }
}

protocol ImportServiceProtocol {
    func importNote(from url: URL) async throws -> Note
    func importNotes(from urls: [URL]) async throws -> [Note]
    func importFromFSNotes(from url: URL) async throws -> [Note]
    func importFromNotesnook(from url: URL) async throws -> [Note]
}

final class ImportService: ImportServiceProtocol {
    
    private let noteStore: NoteStoreProtocol
    
    init(noteStore: NoteStoreProtocol = NoteStore()) {
        self.noteStore = noteStore
    }
    
    func importNote(from url: URL) async throws -> Note {
        guard let format = ImportFormat.detectFormat(from: url) else {
            throw ImportError.invalidFormat
        }
        
        switch format {
        case .markdown, .plainText:
            return try parseMarkdownFile(at: url)
        case .fsNotes:
            throw ImportError.invalidFormat
        case .notesnook:
            throw ImportError.invalidFormat
        }
    }
    
    func importNotes(from urls: [URL]) async throws -> [Note] {
        var notes: [Note] = []
        
        for url in urls {
            do {
                let note = try await importNote(from: url)
                notes.append(note)
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }
        
        return notes
    }
    
    func importFromFSNotes(from url: URL) async throws -> [Note] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImportError.fileNotFound
        }
        
        var notes: [Note] = []
        
        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        guard let fileURLs = enumerator?.allObjects as? [URL] else {
            throw ImportError.parseFailed
        }
        
        for fileURL in fileURLs {
            if fileURL.pathExtension == "md" || fileURL.pathExtension == "txt" {
                do {
                    let note = try parseMarkdownFile(at: fileURL)
                    notes.append(note)
                } catch {
                    print("Failed to import FSNotes file: \(error)")
                }
            }
        }
        
        return notes
    }
    
    func importFromNotesnook(from url: URL) async throws -> [Note] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImportError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        
        struct NotesnookExport: Codable {
            let notes: [NotesnookNote]
        }
        
        struct NotesnookNote: Codable {
            let id: String
            let title: String?
            let content: String
            let tags: [String]?
            let createdAt: Int64?
            let updatedAt: Int64?
        }
        
        let export: NotesnookExport
        do {
            export = try JSONDecoder().decode(NotesnookExport.self, from: data)
        } catch {
            throw ImportError.parseFailed
        }
        
        var notes: [Note] = []
        
        for nnNote in export.notes {
            let title = nnNote.title ?? "Untitled"
            let content = nnNote.content
            
            let createdAt = nnNote.createdAt.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
            let modifiedAt = nnNote.updatedAt.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
            
            let note = Note(
                id: UUID().uuidString,
                title: title,
                content: content,
                encryptedContent: nil,
                tags: nnNote.tags ?? [],
                isPinned: false,
                isFavorite: false,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                syncMetadata: nil
            )
            
            notes.append(note)
        }
        
        return notes
    }
    
    private func parseMarkdownFile(at url: URL) throws -> Note {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        let lines = content.components(separatedBy: .newlines)
        
        var title = "Untitled"
        var tags: [String] = []
        var contentStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("# ") {
                title = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                contentStartIndex = index + 1
            } else if trimmedLine.hasPrefix("**Tags:**") || trimmedLine.hasPrefix("Tags:") {
                let tagsString = trimmedLine.components(separatedBy: ":").last ?? ""
                tags = tagsString
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                contentStartIndex = index + 1
            } else if !trimmedLine.isEmpty {
                break
            }
        }
        
        let noteContent = lines.suffix(from: contentStartIndex)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let fileManager = FileManager.default
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let createdAt = attributes?[.creationDate] as? Date ?? Date()
        let modifiedAt = attributes?[.modificationDate] as? Date ?? Date()
        
        return Note(
            id: UUID().uuidString,
            title: title,
            content: noteContent.isEmpty ? content : noteContent,
            encryptedContent: nil,
            tags: tags,
            isPinned: false,
            isFavorite: false,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            syncMetadata: nil
        )
    }
    
    private func parsePlainTextFile(at url: URL) throws -> Note {
        let content = try String(contentsOf: url, encoding: .utf8)
        
        let lines = content.components(separatedBy: .newlines)
        
        var title = "Untitled"
        var contentStartIndex = 0
        
        if let firstLine = lines.first, !firstLine.trimmingCharacters(in: .whitespaces).isEmpty {
            title = firstLine.trimmingCharacters(in: .whitespaces)
            
            if lines.count > 1 && lines[safe: 1]?.trimmingCharacters(in: .whitespaces).hasPrefix("===") == true {
                contentStartIndex = 2
            } else {
                contentStartIndex = 1
            }
        }
        
        let noteContent = lines.suffix(from: contentStartIndex)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Note(
            id: UUID().uuidString,
            title: title,
            content: noteContent,
            encryptedContent: nil,
            tags: [],
            isPinned: false,
            isFavorite: false,
            createdAt: Date(),
            modifiedAt: Date(),
            syncMetadata: nil
        )
    }
}

import Foundation
import SwiftUI

@MainActor
class NoteEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var tags: [String] = []
    @Published var errorMessage: String?
    
    private let note: Note?
    private let repository: NoteRepositoryProtocol
    
    private var originalTitle: String = ""
    private var originalContent: String = ""
    private var originalTags: [String] = []
    
    init(
        note: Note?,
        repository: NoteRepositoryProtocol = ServiceLocator.shared.noteRepository
    ) {
        self.note = note
        self.repository = repository
        
        if let note = note {
            self.title = note.title
            self.content = note.content
            self.tags = note.tags
            self.originalTitle = note.title
            self.originalContent = note.content
            self.originalTags = note.tags
        }
    }
    
    var hasChanges: Bool {
        return title != originalTitle || 
               content != originalContent || 
               tags != originalTags
    }
    
    func save() async {
        errorMessage = nil
        
        do {
            if let existingNote = note {
                var updatedNote = existingNote
                updatedNote.title = title
                updatedNote.content = content
                updatedNote.tags = tags
                try repository.update(updatedNote)
            } else {
                _ = try repository.create(
                    title: title,
                    content: content,
                    tags: tags
                )
            }
        } catch {
            errorMessage = "Failed to save note: \(error.localizedDescription)"
        }
    }
    
    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

import Foundation
import SwiftUI

@MainActor
class NoteListViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository: NoteRepositoryProtocol
    
    init(repository: NoteRepositoryProtocol = ServiceLocator.shared.noteRepository) {
        self.repository = repository
    }
    
    var filteredNotes: [Note] {
        if searchQuery.isEmpty {
            return notes
        }
        
        let lowercasedQuery = searchQuery.lowercased()
        return notes.filter { note in
            note.title.lowercased().contains(lowercasedQuery) ||
            note.content.lowercased().contains(lowercasedQuery) ||
            note.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notes = try repository.getAll()
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteNote(_ note: Note) async {
        do {
            try repository.delete(id: note.id)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = "Failed to delete note: \(error.localizedDescription)"
        }
    }
    
    func togglePin(_ note: Note) async {
        var updatedNote = note
        updatedNote.isPinned.toggle()
        
        do {
            try repository.update(updatedNote)
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = updatedNote
                notes.sort { $0.isPinned && !$1.isPinned }
            }
        } catch {
            errorMessage = "Failed to update note: \(error.localizedDescription)"
        }
    }
    
    func toggleFavorite(_ note: Note) async {
        var updatedNote = note
        updatedNote.isFavorite.toggle()
        
        do {
            try repository.update(updatedNote)
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = updatedNote
            }
        } catch {
            errorMessage = "Failed to update note: \(error.localizedDescription)"
        }
    }
}

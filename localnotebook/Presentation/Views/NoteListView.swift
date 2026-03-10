import SwiftUI

@MainActor
struct NoteListView: View {
    @StateObject private var viewModel: NoteListViewModel
    @State private var showingNewNote = false
    @State private var selectedNote: Note?
    
    init() {
        _viewModel = StateObject(wrappedValue: NoteListViewModel())
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading notes...")
                } else if viewModel.notes.isEmpty {
                    EmptyStateView(
                        title: "No Notes Yet",
                        subtitle: "Tap the + button to create your first note",
                        actionTitle: "Create Note",
                        action: { showingNewNote = true }
                    )
                } else {
                    noteList
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingNewNote = true }) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewNote = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.searchQuery.isEmpty {
                        Button("Cancel") {
                            viewModel.searchQuery = ""
                        }
                    }
                }
                #endif
            }
            .searchable(
                text: $viewModel.searchQuery,
                prompt: "Search notes"
            )
            .sheet(isPresented: $showingNewNote) {
                NoteEditorView(note: nil)
            }
            .sheet(item: $selectedNote) { note in
                NoteEditorView(note: note)
            }
            .refreshable {
                await viewModel.loadNotes()
            }
        }
        .task {
            await viewModel.loadNotes()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var noteList: some View {
        List(viewModel.filteredNotes) { note in
            NoteRowView(note: note)
                .onTapGesture {
                    selectedNote = note
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteNote(note)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        Task {
                            await viewModel.togglePin(note)
                        }
                    } label: {
                        Label(note.isPinned ? "Unpin" : "Pin", 
                              systemImage: note.isPinned ? "pin.slash" : "pin")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        Task {
                            await viewModel.toggleFavorite(note)
                        }
                    } label: {
                        Label(note.isFavorite ? "Unfavorite" : "Favorite", 
                              systemImage: note.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            Text(note.preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(note.modifiedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !note.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct NoteRowView_Previews: PreviewProvider {
    static var previews: some View {
        NoteRowView(note: Note(
            id: UUID().uuidString,
            title: "Sample Note",
            content: "This is a sample note content.",
            encryptedContent: nil,
            tags: ["work", "important"],
            isPinned: true,
            isFavorite: false,
            createdAt: Date(),
            modifiedAt: Date()
        ))
    }
}

#Preview {
    NoteListView()
}

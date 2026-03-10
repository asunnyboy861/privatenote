import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NoteEditorViewModel
    @FocusState private var isTitleFocused: Bool
    
    init(note: Note?) {
        _viewModel = StateObject(wrappedValue: NoteEditorViewModel(note: note))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                titleField
                
                Divider()
                
                contentField
                
                tagsSection
            }
            .navigationTitle(viewModel.title.isEmpty ? "New Note" : "")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.hasChanges)
                    .fontWeight(.semibold)
                }
                #else
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.hasChanges)
                    .fontWeight(.semibold)
                }
                #endif
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var titleField: some View {
        TextField("Title", text: $viewModel.title)
            .font(.title2)
            .fontWeight(.semibold)
            .padding()
            .focused($isTitleFocused)
    }
    
    private var contentField: some View {
        TextEditor(text: $viewModel.content)
            .font(.body)
            .padding(.horizontal)
            .scrollContentBackground(.hidden)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        TagView(tag: tag) {
                            viewModel.removeTag(tag)
                        }
                    }
                    
                    AddTagView { newTag in
                        viewModel.addTag(newTag)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(UIColor.systemBackground))
        #endif
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

struct AddTagView: View {
    @State private var showingAddTag = false
    @State private var newTagText = ""
    let onAddTag: (String) -> Void
    
    var body: some View {
        Group {
            if showingAddTag {
                HStack {
                    TextField("Tag", text: $newTagText)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onSubmit {
                            addTag()
                        }
                    
                    Button("Add") {
                        addTag()
                    }
                    .font(.caption)
                    
                    Button("Cancel") {
                        showingAddTag = false
                        newTagText = ""
                    }
                    .font(.caption)
                }
            } else {
                Button(action: { showingAddTag = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Tag")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onAddTag(trimmed)
        }
        newTagText = ""
        showingAddTag = false
    }
}

#Preview {
    NoteEditorView(note: nil)
}

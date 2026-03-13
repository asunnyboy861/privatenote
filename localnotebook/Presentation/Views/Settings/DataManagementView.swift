import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExportSuccess = false
    @State private var showingImportPicker = false
    @State private var showingExportPicker = false
    @State private var exportURL: URL?
    
    var body: some View {
        Form {
            Section("Export") {
                Button {
                    showingExportPicker = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export All Notes")
                                .foregroundColor(.primary)
                            Text("Save notes as Markdown file")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Import") {
                Button {
                    showingImportPicker = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import Notes")
                                .foregroundColor(.primary)
                            Text("Import from file")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Storage") {
                HStack {
                    Image(systemName: "externaldrive")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Storage Used")
                            .foregroundColor(.primary)
                        Text(viewModel.storageUsage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.storageUsage)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Notes")
                            .foregroundColor(.primary)
                        Text("\(viewModel.noteCount) notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.noteCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Backup") {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Backup")
                            .foregroundColor(.primary)
                        Text("Automatic backup to iCloud")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section {
                Text("Your notes are encrypted before export. The exported file contains encrypted data that can only be decrypted with your password.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Data Management")
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK") {}
        } message: {
            Text("Your notes have been exported successfully.")
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: NotesDocument(notes: []),
            contentType: UTType(filenameExtension: "md") ?? .plainText,
            defaultFilename: "PrivaNote_Export"
        ) { result in
            switch result {
            case .success(let url):
                Task {
                    do {
                        try await viewModel.exportAllNotes(to: url)
                        showingExportSuccess = true
                        HapticFeedback.shared.playSuccess()
                    } catch {
                        print("Export error: \(error)")
                    }
                }
            case .failure(let error):
                print("Export error: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importNotes(from: url)
                }
            case .failure(let error):
                print("Import error: \(error)")
            }
        }
    }
    
    private func importNotes(from url: URL) {
        HapticFeedback.shared.playSuccess()
    }
}

struct NotesDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var notes: [Note]
    
    init(notes: [Note]) {
        self.notes = notes
    }
    
    init(configuration: ReadConfiguration) throws {
        notes = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let content = "PrivaNote Export"
        return FileWrapper(regularFileWithContents: content.data(using: .utf8)!)
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
}

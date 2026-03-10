import SwiftUI

struct EditorSettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section("Markdown") {
                HStack {
                    Image(systemName: "textformat.alt")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Markdown")
                            .foregroundColor(.primary)
                        Text("Format notes with Markdown syntax")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.markdownEnabled },
                        set: { viewModel.toggleMarkdown($0) }
                    ))
                    .labelsHidden()
                }
            }
            
            Section("Editor Features") {
                HStack {
                    Image(systemName: "textformat.size")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Font Size")
                            .foregroundColor(.primary)
                        Text("Body text size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("16 pt")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-correct")
                            .foregroundColor(.primary)
                        Text("Enable spell checking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section("Toolbar") {
                HStack {
                    Image(systemName: "toolbar")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Toolbar")
                            .foregroundColor(.primary)
                        Text("Display formatting toolbar above editor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section {
                Text("Markdown support includes headings, bold, italic, lists, code blocks, and more.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Editor Settings")
    }
}

#Preview {
    NavigationStack {
        EditorSettingsView()
    }
}

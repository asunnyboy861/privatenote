import SwiftUI

struct MarkdownToolbar: View {
    @ObservedObject var viewModel: NoteEditorViewModel
    @Binding var showExtendedFormats: Bool
    
    private let primaryFormats: [MarkdownFormat] = [
        .bold, .italic, .heading1, .heading2,
        .bulletList, .numberedList, .quote, .code, .link
    ]
    
    private let extendedFormats: [MarkdownFormat] = [
        .strikethrough, .heading3, .codeBlock, .image, .horizontalRule
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(showExtendedFormats ? extendedFormats : primaryFormats) { format in
                        ToolbarButton(
                            format: format,
                            action: {
                                viewModel.insertMarkdownFormat(format)
                                HapticFeedback.shared.playClick()
                            }
                        )
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showExtendedFormats.toggle()
                        }
                        HapticFeedback.shared.playSelection()
                    } label: {
                        Image(systemName: showExtendedFormats ? "chevron.left" : "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 32, height: 32)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            
            Divider()
        }
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor))
        #else
        .background(Color(UIColor.secondarySystemBackground))
        #endif
    }
}

struct ToolbarButton: View {
    let format: MarkdownFormat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: format.icon)
                    .font(.system(size: 16, weight: .medium))
                
                if let shortcut = format.shortcut {
                    Text("⌘\(shortcut)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 40, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.clear)
        )
        .help(format.displayName)
        .accessibilityLabel(format.displayName)
    }
}

struct EditorStatusBar: View {
    let wordCount: Int
    let characterCount: Int
    let isMarkdownEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if isMarkdownEnabled {
                Label("Markdown", systemImage: "textformat.alt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(wordCount) words")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(characterCount) characters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor))
        #else
        .background(Color(UIColor.secondarySystemBackground))
        #endif
    }
}

#Preview {
    VStack {
        MarkdownToolbar(
            viewModel: NoteEditorViewModel(note: nil),
            showExtendedFormats: .constant(false)
        )
        
        Spacer()
        
        EditorStatusBar(
            wordCount: 150,
            characterCount: 850,
            isMarkdownEnabled: true
        )
    }
}

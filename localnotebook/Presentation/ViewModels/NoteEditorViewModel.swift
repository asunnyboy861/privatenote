import Foundation
import SwiftUI

@MainActor
class NoteEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var tags: [String] = []
    @Published var errorMessage: String?
    @Published var isPreviewMode: Bool = false
    @Published var cursorPosition: Int = 0
    
    private let note: Note?
    private let repository: NoteRepositoryProtocol
    private let markdownParser: MarkdownParserProtocol
    
    private var originalTitle: String = ""
    private var originalContent: String = ""
    private var originalTags: [String] = []
    
    init(
        note: Note?,
        repository: NoteRepositoryProtocol = ServiceLocator.shared.noteRepository,
        markdownParser: MarkdownParserProtocol = MarkdownParser()
    ) {
        self.note = note
        self.repository = repository
        self.markdownParser = markdownParser
        
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
    
    var isMarkdownEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "markdownEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "markdownEnabled") }
    }
    
    var renderedHTML: String {
        guard isMarkdownEnabled else { return "" }
        return markdownParser.parse(content)
    }
    
    var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }
    
    var characterCount: Int {
        return content.count
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
    
    func togglePreview() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPreviewMode.toggle()
        }
    }
    
    func insertMarkdownFormat(_ format: MarkdownFormat) {
        let (prefix, suffix, placeholder) = format.markers
        
        var newContent = content
        let insertPosition = cursorPosition
        
        if content.isEmpty {
            newContent = placeholder
            cursorPosition = prefix.count
        } else {
            let startIndex = content.index(content.startIndex, offsetBy: min(insertPosition, content.count))
            newContent = content
            newContent.insert(contentsOf: prefix, at: startIndex)
            
            let newCursorPosition = insertPosition + prefix.count
            let endIndex = newContent.index(newContent.startIndex, offsetBy: min(newCursorPosition, newContent.count))
            newContent.insert(contentsOf: placeholder, at: endIndex)
            
            let afterPlaceholderIndex = newContent.index(newContent.startIndex, offsetBy: newCursorPosition + placeholder.count)
            newContent.insert(contentsOf: suffix, at: afterPlaceholderIndex)
            
            cursorPosition = newCursorPosition
        }
        
        content = newContent
    }
    
    func insertTextAtCursor(_ text: String) {
        let insertPosition = cursorPosition
        let startIndex = content.index(content.startIndex, offsetBy: min(insertPosition, content.count))
        content.insert(contentsOf: text, at: startIndex)
        cursorPosition = insertPosition + text.count
    }
}

enum MarkdownFormat: String, CaseIterable, Identifiable {
    case bold
    case italic
    case strikethrough
    case heading1
    case heading2
    case heading3
    case bulletList
    case numberedList
    case quote
    case code
    case codeBlock
    case link
    case image
    case horizontalRule
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .strikethrough: return "Strikethrough"
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .bulletList: return "Bullet List"
        case .numberedList: return "Numbered List"
        case .quote: return "Quote"
        case .code: return "Code"
        case .codeBlock: return "Code Block"
        case .link: return "Link"
        case .image: return "Image"
        case .horizontalRule: return "Horizontal Rule"
        }
    }
    
    var icon: String {
        switch self {
        case .bold: return "text.bold"
        case .italic: return "text.italic"
        case .strikethrough: return "text.strikethrough"
        case .heading1: return "textformat.size.larger"
        case .heading2: return "textformat.size"
        case .heading3: return "textformat.alt"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .quote: return "quote.open"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .codeBlock: return "curlybraces"
        case .link: return "link"
        case .image: return "photo"
        case .horizontalRule: return "minus"
        }
    }
    
    var shortcut: String? {
        switch self {
        case .bold: return "B"
        case .italic: return "I"
        case .heading1: return "1"
        case .heading2: return "2"
        case .heading3: return "3"
        case .link: return "K"
        default: return nil
        }
    }
    
    var markers: (prefix: String, suffix: String, placeholder: String) {
        switch self {
        case .bold:
            return ("**", "**", "bold text")
        case .italic:
            return ("*", "*", "italic text")
        case .strikethrough:
            return ("~~", "~~", "strikethrough text")
        case .heading1:
            return ("# ", "", "Heading 1")
        case .heading2:
            return ("## ", "", "Heading 2")
        case .heading3:
            return ("### ", "", "Heading 3")
        case .bulletList:
            return ("- ", "", "List item")
        case .numberedList:
            return ("1. ", "", "List item")
        case .quote:
            return ("> ", "", "Quote")
        case .code:
            return ("`", "`", "code")
        case .codeBlock:
            return ("```\n", "\n```", "code block")
        case .link:
            return ("[", "](url)", "link text")
        case .image:
            return ("![", "](url)", "alt text")
        case .horizontalRule:
            return ("\n---\n", "", "")
        }
    }
}

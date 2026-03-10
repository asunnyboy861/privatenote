import Foundation
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import CoreGraphics
#endif

enum ExportFormat: String, CaseIterable {
    case markdown
    case pdf
    case plainText
    
    var utType: UTType {
        switch self {
        case .markdown:
            return UTType.init(filenameExtension: "md") ?? .plainText
        case .pdf:
            return .pdf
        case .plainText:
            return .plainText
        }
    }
    
    var fileExtension: String {
        switch self {
        case .markdown:
            return "md"
        case .pdf:
            return "pdf"
        case .plainText:
            return "txt"
        }
    }
}

enum ExportError: LocalizedError {
    case exportFailed
    case fileAccessDenied
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export note. Please try again."
        case .fileAccessDenied:
            return "File access denied. Please grant permission."
        case .invalidFormat:
            return "Invalid export format."
        }
    }
}

protocol ExportServiceProtocol {
    func exportNote(_ note: Note, format: ExportFormat, to url: URL) async throws
    func exportNotes(_ notes: [Note], format: ExportFormat, to url: URL) async throws
}

final class ExportService: ExportServiceProtocol {
    
    func exportNote(_ note: Note, format: ExportFormat, to url: URL) async throws {
        switch format {
        case .markdown:
            try exportAsMarkdown(note, to: url)
        case .pdf:
            try await exportAsPDF(note, to: url)
        case .plainText:
            try exportAsPlainText(note, to: url)
        }
    }
    
    func exportNotes(_ notes: [Note], format: ExportFormat, to url: URL) async throws {
        switch format {
        case .markdown:
            try exportNotesAsMarkdown(notes, to: url)
        case .pdf:
            try await exportNotesAsPDF(notes, to: url)
        case .plainText:
            try exportNotesAsPlainText(notes, to: url)
        }
    }
    
    private func exportAsMarkdown(_ note: Note, to url: URL) throws {
        var content = "# \(note.title)\n\n"
        
        if !note.tags.isEmpty {
            content += "**Tags:** \(note.tags.joined(separator: ", "))\n\n"
        }
        
        content += "\(note.content)\n\n"
        content += "---\n"
        content += "*Created: \(formatDate(note.createdAt))*\n"
        content += "*Modified: \(formatDate(note.modifiedAt))*\n"
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportNotesAsMarkdown(_ notes: [Note], to url: URL) throws {
        var content = "# PrivaNote Export\n\n"
        content += "*Exported on \(formatDate(Date()))*\n\n"
        content += "---\n\n"
        
        for note in notes {
            content += "# \(note.title)\n\n"
            
            if !note.tags.isEmpty {
                content += "**Tags:** \(note.tags.joined(separator: ", "))\n\n"
            }
            
            content += "\(note.content)\n\n"
            content += "---\n\n"
        }
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportAsPDF(_ note: Note, to url: URL) async throws {
        #if os(iOS)
        try await exportNoteAsPDFiOS(note, to: url)
        #elseif os(macOS)
        try await exportNoteAsPDFmacOS(note, to: url)
        #endif
    }
    
    private func exportNotesAsPDF(_ notes: [Note], to url: URL) async throws {
        #if os(iOS)
        try await exportNotesAsPDFiOS(notes, to: url)
        #elseif os(macOS)
        try await exportNotesAsPDFmacOS(notes, to: url)
        #endif
    }
    
    #if os(iOS)
    private func exportNoteAsPDFiOS(_ note: Note, to url: URL) async throws {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .paragraphStyle: paragraphStyle
            ]
            
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            let titleRect = CGRect(x: 36, y: 36, width: 540, height: 40)
            note.title.draw(in: titleRect, withAttributes: titleAttributes)
            
            let contentRect = CGRect(x: 36, y: 100, width: 540, height: 656)
            note.content.draw(in: contentRect, withAttributes: contentAttributes)
        }
        
        try data.write(to: url)
    }
    
    private func exportNotesAsPDFiOS(_ notes: [Note], to url: URL) async throws {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let data = renderer.pdfData { ctx in
            for (index, note) in notes.enumerated() {
                if index > 0 {
                    ctx.beginPage()
                }
                
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24)
                ]
                
                let contentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                
                note.title.draw(at: CGPoint(x: 36, y: 36), withAttributes: titleAttributes)
                
                let contentRect = CGRect(x: 36, y: 80, width: 540, height: 676)
                note.content.draw(in: contentRect, withAttributes: contentAttributes)
            }
        }
        
        try data.write(to: url)
    }
    #endif
    
    #if os(macOS)
    private func exportNoteAsPDFmacOS(_ note: Note, to url: URL) async throws {
        let pdfInfo: [String: Any] = [
            kCGPDFContextCreator as String: "PrivaNote",
            kCGPDFContextAuthor as String: "PrivaNote User"
        ]
        
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw ExportError.exportFailed
        }
        
        guard let context = CGContext(consumer: consumer, mediaBox: nil, pdfInfo as CFDictionary) else {
            throw ExportError.exportFailed
        }
        
        context.beginPDFPage(nil)
        
        let titleFont = NSFont.boldSystemFont(ofSize: 24)
        let contentFont = NSFont.systemFont(ofSize: 12)
        
        let titleRect = NSRect(x: 36, y: 756, width: 540, height: 30)
        note.title.draw(in: titleRect, withAttributes: [.font: titleFont])
        
        let contentRect = NSRect(x: 36, y: 50, width: 540, height: 700)
        note.content.draw(in: contentRect, withAttributes: [.font: contentFont])
        
        context.endPDFPage()
        context.closePDF()
    }
    
    private func exportNotesAsPDFmacOS(_ notes: [Note], to url: URL) async throws {
        let pdfInfo: [String: Any] = [
            kCGPDFContextCreator as String: "PrivaNote",
            kCGPDFContextAuthor as String: "PrivaNote User"
        ]
        
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw ExportError.exportFailed
        }
        
        guard let context = CGContext(consumer: consumer, mediaBox: nil, pdfInfo as CFDictionary) else {
            throw ExportError.exportFailed
        }
        
        for note in notes {
            var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
            let mediaBoxData = withUnsafeMutablePointer(to: &mediaBox) { ptr in
                NSData(bytes: ptr, length: MemoryLayout<CGRect>.size) as CFData
            }
            let pageDict: [String: Any] = [kCGPDFContextMediaBox as String: mediaBoxData]
            context.beginPDFPage(pageDict as CFDictionary)
            
            let titleFont = NSFont.boldSystemFont(ofSize: 24)
            let contentFont = NSFont.systemFont(ofSize: 12)
            
            let titleRect = NSRect(x: 36, y: 756, width: 540, height: 30)
            note.title.draw(in: titleRect, withAttributes: [.font: titleFont])
            
            let contentRect = NSRect(x: 36, y: 50, width: 540, height: 700)
            note.content.draw(in: contentRect, withAttributes: [.font: contentFont])
            
            context.endPDFPage()
        }
        
        context.closePDF()
    }
    #endif
    
    private func exportAsPlainText(_ note: Note, to url: URL) throws {
        var content = "\(note.title)\n"
        content += "\(String(repeating: "=", count: note.title.count))\n\n"
        
        if !note.tags.isEmpty {
            content += "Tags: \(note.tags.joined(separator: ", "))\n\n"
        }
        
        content += "\(note.content)\n"
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportNotesAsPlainText(_ notes: [Note], to url: URL) throws {
        var content = "PrivaNote Export - \(formatDate(Date()))\n"
        content += "\(String(repeating: "=", count: 50))\n\n"
        
        for note in notes {
            content += "\(note.title)\n"
            content += "\(String(repeating: "=", count: note.title.count))\n\n"
            
            if !note.tags.isEmpty {
                content += "Tags: \(note.tags.joined(separator: ", "))\n\n"
            }
            
            content += "\(note.content)\n\n"
            content += "\(String(repeating: "-", count: 50))\n\n"
        }
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

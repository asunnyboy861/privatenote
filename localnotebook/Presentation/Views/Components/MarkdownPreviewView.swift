import SwiftUI

struct MarkdownPreviewView: View {
    let html: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(htmlToAttributedString(html))
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func htmlToAttributedString(_ html: String) -> AttributedString {
        do {
            let attributedString = try AttributedString(
                html: html,
                options: AttributedString.HTMLParsingOptions(
                    allowsHTMLElements: true
                )
            )
            return attributedString
        } catch {
            return AttributedString(html)
        }
    }
}

struct MarkdownPreviewViewSimple: View {
    let html: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parseHTML(html), id: \.self) { block in
                    renderBlock(block)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func parseHTML(_ html: String) -> [String] {
        return html.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }
    
    @ViewBuilder
    private func renderBlock(_ block: String) -> some View {
        if block.hasPrefix("<h1>") {
            Text(stripHTMLTags(block))
                .font(.system(size: 28, weight: .bold))
        } else if block.hasPrefix("<h2>") {
            Text(stripHTMLTags(block))
                .font(.system(size: 24, weight: .bold))
        } else if block.hasPrefix("<h3>") {
            Text(stripHTMLTags(block))
                .font(.system(size: 20, weight: .semibold))
        } else if block.hasPrefix("<blockquote>") {
            HStack {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 4)
                
                Text(stripHTMLTags(block))
                    .font(.body.italic())
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 4)
        } else if block.hasPrefix("<pre>") {
            Text(stripHTMLTags(block))
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        } else if block.hasPrefix("<ul>") || block.hasPrefix("<ol>") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(parseListItems(block), id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(stripHTMLTags(item))
                    }
                }
            }
        } else {
            Text(stripHTMLTags(block))
                .font(.body)
        }
    }
    
    private func stripHTMLTags(_ html: String) -> String {
        return html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
    
    private func parseListItems(_ html: String) -> [String] {
        return html
            .components(separatedBy: "<li>")
            .dropFirst()
            .map { $0.replacingOccurrences(of: "</li>", with: "") }
    }
}

#Preview {
    MarkdownPreviewView(html: "<h1>Hello World</h1><p>This is a <strong>test</strong> paragraph.</p>")
}

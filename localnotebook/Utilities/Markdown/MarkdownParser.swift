import Foundation

struct MarkdownParser: MarkdownParserProtocol {
    func parse(_ markdown: String) -> String {
        var html = markdown
        
        html = escapeHTML(html)
        html = parseCodeBlocks(html)
        html = parseHeaders(html)
        html = parseBold(html)
        html = parseItalic(html)
        html = parseStrikethrough(html)
        html = parseLinks(html)
        html = parseImages(html)
        html = parseBulletList(html)
        html = parseOrderedList(html)
        html = parseBlockquotes(html)
        html = parseInlineCode(html)
        html = parseHorizontalRule(html)
        html = parseParagraphs(html)
        
        return html
    }
    
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
    
    private func parseHeaders(_ text: String) -> String {
        var result = text
        
        result = result.replacingOccurrences(
            of: #"^###### (.+)$"#,
            with: "<h6>$1</h6>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^##### (.+)$"#,
            with: "<h5>$1</h5>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^#### (.+)$"#,
            with: "<h4>$1</h4>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^### (.+)$"#,
            with: "<h3>$1</h3>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^## (.+)$"#,
            with: "<h2>$1</h2>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^# (.+)$"#,
            with: "<h1>$1</h1>",
            options: .regularExpression
        )
        
        return result
    }
    
    private func parseBold(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: #"\*\*\*(.+?)\*\*\*"#,
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"___(.+?)___"#,
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"__(.+?)__"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        return result
    }
    
    private func parseItalic(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: #"\*(.+?)\*"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"_(.+?)_"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )
        return result
    }
    
    private func parseStrikethrough(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"~~(.+?)~~"#,
            with: "<del>$1</del>",
            options: .regularExpression
        )
    }
    
    private func parseLinks(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"\[(.+?)\]\((.+?)\)"#,
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )
    }
    
    private func parseImages(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"!\[(.+?)\]\((.+?)\)"#,
            with: "<img src=\"$2\" alt=\"$1\" />",
            options: .regularExpression
        )
    }
    
    private func parseBulletList(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var inList = false
        var result: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                if !inList {
                    result.append("<ul>")
                    inList = true
                }
                let content = String(trimmed.dropFirst(2))
                result.append("<li>\(content)</li>")
            } else {
                if inList {
                    result.append("</ul>")
                    inList = false
                }
                result.append(line)
            }
        }
        
        if inList {
            result.append("</ul>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private func parseOrderedList(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var inList = false
        var result: [String] = []
        
        let listPattern = #"^\d+\.\s"#
        
        for line in lines {
            if let range = line.range(of: listPattern, options: .regularExpression) {
                if !inList {
                    result.append("<ol>")
                    inList = true
                }
                let content = String(line[range.upperBound...])
                result.append("<li>\(content)</li>")
            } else {
                if inList {
                    result.append("</ol>")
                    inList = false
                }
                result.append(line)
            }
        }
        
        if inList {
            result.append("</ol>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private func parseBlockquotes(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var inQuote = false
        var result: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("> ") {
                if !inQuote {
                    result.append("<blockquote>")
                    inQuote = true
                }
                let content = String(trimmed.dropFirst(2))
                result.append(content)
            } else {
                if inQuote {
                    result.append("</blockquote>")
                    inQuote = false
                }
                result.append(line)
            }
        }
        
        if inQuote {
            result.append("</blockquote>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private func parseInlineCode(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "<code>$1</code>",
            options: .regularExpression
        )
    }
    
    private func parseCodeBlocks(_ text: String) -> String {
        return text.replacingOccurrences(
            of: #"```(\w*)\n([\s\S]+?)\n```"#,
            with: "<pre><code class=\"$1\">$2</code></pre>",
            options: .regularExpression
        )
    }
    
    private func parseHorizontalRule(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: #"^---$"#,
            with: "<hr />",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^\*\*\*$"#,
            with: "<hr />",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"^___$"#,
            with: "<hr />",
            options: .regularExpression
        )
        return result
    }
    
    private func parseParagraphs(_ text: String) -> String {
        let blocks = text.components(separatedBy: "\n\n")
        return blocks.map { block in
            let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            
            if !trimmed.hasPrefix("<") {
                return "<p>\(trimmed)</p>"
            }
            return trimmed
        }.joined(separator: "\n\n")
    }
}

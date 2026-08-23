import AppKit
import Foundation

enum CodeLanguage: String, CaseIterable {
    case swift
    case python
    case javascript
    case json
    case shell
    case sql
    case plain
}

enum CodeDetector {
    static func isCodeLike(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return false }
        if trimmed.hasPrefix("#!") { return true }
        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") { return true }
        if trimmed.contains("func ") || trimmed.contains("def ") || trimmed.contains("function ") {
            return true
        }
        if trimmed.contains("import ") && (trimmed.contains("\n") || trimmed.contains("{")) {
            return true
        }
        let codeChars = CharacterSet(charactersIn: "{}();[]=<>")
        let ratio = Double(trimmed.unicodeScalars.filter { codeChars.contains($0) }.count) / Double(trimmed.count)
        return ratio > 0.04 && trimmed.contains("\n")
    }

    static func detectLanguage(text: String, sourceBundleID: String?) -> CodeLanguage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if let bundleID = sourceBundleID {
            if bundleID.contains("Xcode") || bundleID.contains("vscode") || bundleID.contains("cursor") {
                if lower.contains("import swift") || lower.contains("struct ") || lower.contains("func ") {
                    return .swift
                }
            }
        }

        if trimmed.hasPrefix("#!/bin/bash") || trimmed.hasPrefix("#!/bin/zsh") || trimmed.hasPrefix("#!/usr/bin/env") {
            return .shell
        }
        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
            if (try? JSONSerialization.jsonObject(with: Data(trimmed.utf8))) != nil {
                return .json
            }
        }
        if lower.contains("select ") && lower.contains(" from ") { return .sql }
        if lower.contains("def ") || lower.contains("import ") && lower.contains("print(") { return .python }
        if lower.contains("function ") || lower.contains("const ") || lower.contains("let ") && lower.contains("=>") {
            return .javascript
        }
        if lower.contains("func ") || lower.contains("struct ") || lower.contains("enum ") { return .swift }
        return .plain
    }
}

enum CodeHighlighter {
    static func highlight(text: String, language: CodeLanguage) -> AttributedString {
        var result = AttributedString(text)
        result.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        result.foregroundColor = NSColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1)

        let keywords: [String]
        switch language {
        case .swift:
            keywords = ["import", "struct", "class", "enum", "func", "let", "var", "return", "if", "else", "guard", "switch", "case", "true", "false", "nil", "public", "private", "static"]
        case .python:
            keywords = ["def", "class", "import", "from", "return", "if", "elif", "else", "for", "while", "True", "False", "None", "with", "as", "pass"]
        case .javascript:
            keywords = ["function", "const", "let", "var", "return", "if", "else", "for", "while", "class", "import", "export", "true", "false", "null", "undefined", "async", "await"]
        case .json:
            keywords = ["true", "false", "null"]
        case .shell:
            keywords = ["if", "then", "else", "fi", "for", "do", "done", "echo", "export"]
        case .sql:
            keywords = ["select", "from", "where", "insert", "into", "values", "update", "set", "delete", "join", "on", "and", "or", "order", "by", "limit"]
        case .plain:
            keywords = []
        }

        highlightComments(in: &result, text: text, language: language)
        highlightStrings(in: &result, text: text)
        highlightKeywords(in: &result, text: text, keywords: keywords)
        return result
    }

    private static func highlightKeywords(in result: inout AttributedString, text: String, keywords: [String]) {
        for keyword in keywords {
            applyStyle(to: &result, in: text, pattern: "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b", color: NSColor(red: 0.95, green: 0.45, blue: 0.75, alpha: 1))
        }
    }

    private static func highlightStrings(in result: inout AttributedString, text: String) {
        applyStyle(to: &result, in: text, pattern: #""(?:\\.|[^"\\])*""#, color: NSColor(red: 0.98, green: 0.76, blue: 0.44, alpha: 1))
        applyStyle(to: &result, in: text, pattern: #"\'(?:\\.|[^'\\])*\'"#, color: NSColor(red: 0.98, green: 0.76, blue: 0.44, alpha: 1))
    }

    private static func highlightComments(in result: inout AttributedString, text: String, language: CodeLanguage) {
        switch language {
        case .swift, .javascript:
            applyStyle(to: &result, in: text, pattern: #"//.*$"#, color: NSColor(red: 0.45, green: 0.55, blue: 0.45, alpha: 1), options: [.anchorsMatchLines])
        case .python, .shell:
            applyStyle(to: &result, in: text, pattern: #"#.*$"#, color: NSColor(red: 0.45, green: 0.55, blue: 0.45, alpha: 1), options: [.anchorsMatchLines])
        case .sql:
            applyStyle(to: &result, in: text, pattern: #"--.*$"#, color: NSColor(red: 0.45, green: 0.55, blue: 0.45, alpha: 1), options: [.anchorsMatchLines])
        default:
            break
        }
    }

    private static func applyStyle(
        to result: inout AttributedString,
        in text: String,
        pattern: String,
        color: NSColor,
        options: NSRegularExpression.Options = []
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            guard let swiftRange = Range(match.range, in: text),
                  let attrRange = Range(swiftRange, in: result) else { continue }
            result[attrRange].foregroundColor = color
        }
    }
}

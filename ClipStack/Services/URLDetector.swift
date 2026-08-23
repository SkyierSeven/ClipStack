import Foundation

enum URLDetector {
    static func containsHTTPURL(in text: String) -> Bool {
        !extractHTTPURLs(from: text).isEmpty
    }

    static func primaryURL(in text: String) -> String? {
        extractHTTPURLs(from: text).first
    }

    static func classifyText(_ text: String) -> ClipboardContentType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .text }

        if isStandaloneHTTPURL(trimmed) || containsHTTPURL(in: trimmed) {
            return .url
        }

        return .text
    }

    static func extractHTTPURLs(from text: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard match.resultType == .link, let url = match.url else { return nil }
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
                return nil
            }
            return url.absoluteString
        }
    }

    private static func isStandaloneHTTPURL(_ text: String) -> Bool {
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }
}

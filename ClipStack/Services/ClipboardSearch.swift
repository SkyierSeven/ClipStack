import Foundation

struct ClipboardSearch {
    struct ParsedQuery: Equatable {
        let raw: String
        let tokens: [String]
        let contentType: ClipboardContentType?
        let appFilter: String?
        let pinboardFilter: String?
    }

    static func parse(_ raw: String) -> ParsedQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var tokens: [String] = []
        var contentType: ClipboardContentType?
        var appFilter: String?
        var pinboardFilter: String?

        for part in trimmed.split(whereSeparator: \.isWhitespace) {
            let segment = String(part)
            let lower = segment.lowercased()

            if lower.hasPrefix("type:") || lower.hasPrefix("类型:") {
                let value = segment.split(separator: ":", maxSplits: 1).last.map(String.init) ?? ""
                contentType = parseContentType(value)
                continue
            }

            if lower.hasPrefix("app:") || lower.hasPrefix("应用:") {
                appFilter = segment.split(separator: ":", maxSplits: 1).last.map(String.init) ?? ""
                continue
            }

            if lower.hasPrefix("pin:") || lower.hasPrefix("固定:") {
                pinboardFilter = segment.split(separator: ":", maxSplits: 1).last.map(String.init) ?? ""
                continue
            }

            tokens.append(segment)
        }

        return ParsedQuery(
            raw: trimmed,
            tokens: tokens,
            contentType: contentType,
            appFilter: appFilter,
            pinboardFilter: pinboardFilter
        )
    }

    static func matches(
        item: ClipboardItem,
        query: ParsedQuery,
        pinboardName: String?
    ) -> Bool {
        guard !query.raw.isEmpty else { return true }

        if let contentType = query.contentType, item.type != contentType {
            return false
        }

        if let appFilter = query.appFilter?.lowercased(), !appFilter.isEmpty {
            let appHaystack = [
                item.sourceAppName?.lowercased(),
                item.sourceBundleID?.lowercased(),
            ].compactMap { $0 }
            guard appHaystack.contains(where: { $0.contains(appFilter) }) else {
                return false
            }
        }

        if let pinboardFilter = query.pinboardFilter?.lowercased(), !pinboardFilter.isEmpty {
            guard let pinboardName, pinboardName.lowercased().contains(pinboardFilter) else {
                return false
            }
        }

        if query.tokens.isEmpty {
            return true
        }

        let haystack = searchableText(for: item, pinboardName: pinboardName)
        return query.tokens.allSatisfy { token in
            haystack.contains(token.lowercased())
        }
    }

    static func score(item: ClipboardItem, query: ParsedQuery, pinboardName: String?) -> Int {
        guard !query.tokens.isEmpty else { return 0 }
        let haystack = searchableText(for: item, pinboardName: pinboardName)
        var score = 0

        for token in query.tokens {
            let needle = token.lowercased()
            if haystack.hasPrefix(needle) { score += 12 }
            if haystack.contains(needle) { score += 6 }
            if item.text?.lowercased().contains(needle) == true { score += 4 }
            if item.sourceAppName?.lowercased().contains(needle) == true { score += 2 }
        }

        if item.pinboardID != nil { score += 1 }
        return score
    }

    private static func searchableText(for item: ClipboardItem, pinboardName: String?) -> String {
        var parts: [String] = [
            item.previewText,
            item.text ?? "",
            item.searchIndex ?? "",
            item.sourceAppName ?? "",
            item.sourceBundleID ?? "",
            pinboardName ?? "",
            typeLabel(for: item.type),
        ]
        parts.append(contentsOf: item.filePaths)
        return parts.joined(separator: "\n").lowercased()
    }

    private static func parseContentType(_ value: String) -> ClipboardContentType? {
        switch value.lowercased() {
        case "text", "文本", "txt": .text
        case "url", "链接", "link": .url
        case "image", "图片", "img", "photo": .image
        case "file", "文件": .file
        default: ClipboardContentType(rawValue: value.lowercased())
        }
    }

    private static func typeLabel(for type: ClipboardContentType) -> String {
        switch type {
        case .text: "文本"
        case .url: "链接"
        case .image: "图片"
        case .file: "文件"
        }
    }
}

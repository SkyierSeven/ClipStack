import AppKit
import Foundation

enum ClipboardContentType: String, Codable, CaseIterable {
    case text
    case image
    case file
    case url
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ClipboardContentType
    let text: String?
    var imagePath: String?
    let filePaths: [String]
    let sourceAppName: String?
    let sourceBundleID: String?
    let createdAt: Date
    var pinboardID: UUID?
    var searchIndex: String?

    /// Legacy field for migration from single-file JSON storage.
    private let imageData: Data?

    init(
        id: UUID = UUID(),
        type: ClipboardContentType,
        text: String? = nil,
        imageData: Data? = nil,
        imagePath: String? = nil,
        filePaths: [String] = [],
        sourceAppName: String? = nil,
        sourceBundleID: String? = nil,
        createdAt: Date = Date(),
        pinboardID: UUID? = nil,
        searchIndex: String? = nil
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.imageData = imageData
        self.imagePath = imagePath
        self.filePaths = filePaths
        self.sourceAppName = sourceAppName
        self.sourceBundleID = sourceBundleID
        self.createdAt = createdAt
        self.pinboardID = pinboardID
        self.searchIndex = searchIndex
    }

    var previewText: String {
        switch type {
        case .text, .url:
            let value = text ?? ""
            if type == .url, let url = URLDetector.primaryURL(in: value) {
                return url
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "空文本" }
            return trimmed.replacingOccurrences(of: "\n", with: " ")
        case .image:
            return "图片"
        case .file:
            if filePaths.count == 1, let name = filePaths.first?.split(separator: "/").last {
                return String(name)
            }
            return "\(filePaths.count) 个文件"
        }
    }

    var typeIcon: String {
        switch type {
        case .text:
            if let text, CodeDetector.isCodeLike(text) { return "chevron.left.forwardslash.chevron.right" }
            return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        case .url: return "link"
        }
    }

    var isCodeSnippet: Bool {
        guard type == .text || type == .url, let text else { return false }
        return CodeDetector.isCodeLike(text)
    }

    var codeLanguage: CodeLanguage {
        guard let text else { return .plain }
        return CodeDetector.detectLanguage(text: text, sourceBundleID: sourceBundleID)
    }

    var resolvedImageData: Data? {
        if let imagePath {
            return ImageAssetStore.shared.loadImage(relativePath: imagePath)
        }
        return imageData
    }

    var thumbnailImage: NSImage? {
        guard type == .image, let data = resolvedImageData else { return nil }
        return NSImage(data: data)
    }

    func matchesSearch(_ query: String, pinboardName: String? = nil) -> Bool {
        ClipboardSearch.matches(
            item: self,
            query: ClipboardSearch.parse(query),
            pinboardName: pinboardName
        )
    }

    var displayTextForSearch: String {
        if let searchIndex, !searchIndex.isEmpty, type == .image {
            let preview = searchIndex
                .replacingOccurrences(of: "\n", with: " ")
            if preview.count > 120 {
                return String(preview.prefix(120)) + "…"
            }
            return preview
        }
        return previewText
    }

    mutating func migrateLegacyImageIfNeeded() {
        guard imagePath == nil, let imageData else { return }
        if let path = ImageAssetStore.shared.saveImage(data: imageData, itemID: id) {
            imagePath = path
        }
    }

    func withPersistedImage() -> ClipboardItem {
        var copy = self
        if copy.type == .image, copy.imagePath == nil, let data = copy.legacyImageData ?? copy.resolvedImageData {
            copy.imagePath = ImageAssetStore.shared.saveImage(data: data, itemID: copy.id)
        }
        return ClipboardItem(
            id: copy.id,
            type: copy.type,
            text: copy.text,
            imagePath: copy.imagePath,
            filePaths: copy.filePaths,
            sourceAppName: copy.sourceAppName,
            sourceBundleID: copy.sourceBundleID,
            createdAt: copy.createdAt,
            pinboardID: copy.pinboardID,
            searchIndex: copy.searchIndex
        )
    }

    private var legacyImageData: Data? { imageData }

    private enum CodingKeys: String, CodingKey {
        case id, type, text, imagePath, imageData, filePaths
        case sourceAppName, sourceBundleID, createdAt, pinboardID, searchIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ClipboardContentType.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        filePaths = try container.decodeIfPresent([String].self, forKey: .filePaths) ?? []
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
        sourceBundleID = try container.decodeIfPresent(String.self, forKey: .sourceBundleID)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        pinboardID = try container.decodeIfPresent(UUID.self, forKey: .pinboardID)
        searchIndex = try container.decodeIfPresent(String.self, forKey: .searchIndex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
        try container.encode(filePaths, forKey: .filePaths)
        try container.encodeIfPresent(sourceAppName, forKey: .sourceAppName)
        try container.encodeIfPresent(sourceBundleID, forKey: .sourceBundleID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(pinboardID, forKey: .pinboardID)
        try container.encodeIfPresent(searchIndex, forKey: .searchIndex)
    }
}

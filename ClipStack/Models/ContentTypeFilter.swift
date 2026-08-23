import Foundation

enum ContentTypeFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case text = "文字"
    case url = "链接"
    case image = "图片"
    case file = "文件"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .text: "doc.text"
        case .url: "link"
        case .image: "photo"
        case .file: "doc"
        }
    }

    func matches(_ item: ClipboardItem) -> Bool {
        switch self {
        case .all:
            return true
        case .text:
            return item.type == .text
        case .url:
            return item.type == .url || URLDetector.containsHTTPURL(in: item.text ?? "")
        case .image:
            return item.type == .image
        case .file:
            return item.type == .file
        }
    }
}

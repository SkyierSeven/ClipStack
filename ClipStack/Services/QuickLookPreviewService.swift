import AppKit
import QuickLookUI

/// Presents clipboard items with macOS Quick Look (`QLPreviewPanel`).
final class QuickLookPreviewService: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookPreviewService()

    private var previewURLs: [URL] = []
    private var temporaryURLs: [URL] = []

    private override init() {
        super.init()
    }

    @MainActor
    func preview(_ item: ClipboardItem) {
        cleanupTemporaryFiles()
        previewURLs = makePreviewURLs(for: item)
        guard !previewURLs.isEmpty else { return }
        guard let panel = QLPreviewPanel.shared() else { return }

        // Ensure ClipStack can own the Quick Look panel even as a menu-bar app.
        NSApp.activate(ignoringOtherApps: true)
        panel.dataSource = self
        panel.delegate = self
        panel.currentPreviewItemIndex = 0
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    @MainActor
    func previewSelectedItem(from appState: AppState) {
        guard let selectedID = appState.selectedItemID,
              let item = appState.currentDisplayItems.first(where: { $0.id == selectedID }) else { return }
        preview(item)
    }

    // MARK: - Called from KeyablePanel / responder chain

    func prepareToControlPreviewPanel(_ panel: QLPreviewPanel) {
        panel.dataSource = self
        panel.delegate = self
    }

    func finishControllingPreviewPanel(_ panel: QLPreviewPanel) {
        panel.dataSource = nil
        panel.delegate = nil
        cleanupTemporaryFiles()
        previewURLs = []
    }

    var hasPreviewItems: Bool {
        !previewURLs.isEmpty
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURLs.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        guard previewURLs.indices.contains(index) else { return nil }
        return previewURLs[index] as NSURL
    }

    // MARK: - Private

    private func makePreviewURLs(for item: ClipboardItem) -> [URL] {
        switch item.type {
        case .file:
            return item.filePaths
                .map { URL(fileURLWithPath: $0) }
                .filter { FileManager.default.fileExists(atPath: $0.path) }

        case .image:
            if let relative = item.imagePath {
                let url = ImageAssetStore.shared.absoluteURL(forRelativePath: relative)
                if FileManager.default.fileExists(atPath: url.path) {
                    return [url]
                }
            }
            if let data = item.resolvedImageData,
               let url = writeTemporaryData(data, extension: "png") {
                return [url]
            }
            return []

        case .text, .url:
            guard let text = item.text, !text.isEmpty else { return [] }
            let fileExtension = preferredTextExtension(for: item)
            if let url = writeTemporaryText(text, extension: fileExtension) {
                return [url]
            }
            return []
        }
    }

    private func preferredTextExtension(for item: ClipboardItem) -> String {
        if item.type == .url { return "txt" }
        switch item.codeLanguage {
        case .swift: return "swift"
        case .python: return "py"
        case .javascript: return "js"
        case .json: return "json"
        case .shell: return "sh"
        case .sql: return "sql"
        case .plain: return "txt"
        }
    }

    private func writeTemporaryText(_ text: String, extension fileExtension: String) -> URL? {
        guard let data = text.data(using: .utf8) else { return nil }
        return writeTemporaryData(data, extension: fileExtension)
    }

    private func writeTemporaryData(_ data: Data, extension fileExtension: String) -> URL? {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipStackQuickLook", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)
            try data.write(to: url, options: .atomic)
            temporaryURLs.append(url)
            return url
        } catch {
            NSLog("ClipStack Quick Look temp write failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func cleanupTemporaryFiles() {
        for url in temporaryURLs {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryURLs.removeAll()
    }
}

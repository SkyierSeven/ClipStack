import AppKit
import Foundation

@MainActor
final class ClipboardMonitor {
    private let appState: AppState
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var isInternalWrite = false

    init(appState: AppState) {
        self.appState = appState
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func markInternalWrite() {
        isInternalWrite = true
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        guard !appState.isMonitoringPaused else { return }

        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        if isInternalWrite {
            isInternalWrite = false
            return
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let bundleID = frontApp.bundleIdentifier
        if let bundleID, appState.excludedBundleIDs.contains(bundleID) {
            return
        }

        guard let item = readItem(from: pasteboard, sourceApp: frontApp.localizedName, bundleID: bundleID) else {
            return
        }

        appState.addItem(item)
    }

    private func readItem(from pasteboard: NSPasteboard, sourceApp: String?, bundleID: String?) -> ClipboardItem? {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true,
        ]) as? [URL], !urls.isEmpty {
            let paths = urls.map(\.path)
            return ClipboardItem(
                type: .file,
                filePaths: paths,
                sourceAppName: sourceApp,
                sourceBundleID: bundleID
            )
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            return ClipboardItem(
                type: .image,
                imageData: png,
                sourceAppName: sourceApp,
                sourceBundleID: bundleID
            )
        }

        if let string = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !string.isEmpty {
            return ClipboardItem(
                type: URLDetector.classifyText(string),
                text: string,
                sourceAppName: sourceApp,
                sourceBundleID: bundleID
            )
        }

        return nil
    }
}

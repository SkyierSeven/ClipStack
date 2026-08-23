import AppKit
import ApplicationServices
import Carbon.HIToolbox

enum ClipboardInsertService {
    static func insert(_ item: ClipboardItem, asPlainText: Bool = false) {
        writeToClipboard(item, asPlainText: asPlainText)
        simulateCommandV()
    }

    static func writeToClipboard(_ item: ClipboardItem, asPlainText: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .url:
            if asPlainText, let text = item.text {
                pasteboard.setString(text, forType: .string)
            } else if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let imageData = item.resolvedImageData, let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        case .file:
            let urls = item.filePaths.compactMap { URL(fileURLWithPath: $0) as NSURL }
            if !urls.isEmpty {
                pasteboard.writeObjects(urls)
            }
        }
    }

    private static func simulateCommandV() {
        guard AXIsProcessTrusted() else {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "ClipStack 需要辅助功能权限才能自动插入内容。请在系统设置中授权，或手动按 ⌘V。"
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "知道了")
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}

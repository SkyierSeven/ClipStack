import AppKit
import ApplicationServices
import Carbon.HIToolbox

enum ClipboardInsertService {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAccessibilityPermission(prompt: Bool = true) -> Bool {
        if AXIsProcessTrusted() { return true }
        guard prompt else { return false }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    static func writeToClipboard(_ item: ClipboardItem, asPlainText: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .url:
            if let text = item.text {
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

    /// Posts ⌘V. Caller should restore focus to the target app first.
    static func paste(showingPromptIfNeeded: Bool = true) -> Bool {
        guard requestAccessibilityPermission(prompt: showingPromptIfNeeded) else {
            if showingPromptIfNeeded {
                presentAccessibilityAlert()
            }
            return false
        }

        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
        return true
    }

    private static func presentAccessibilityAlert() {
        let appPath = Bundle.main.bundlePath
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = """
        ClipStack 需要辅助功能权限才能自动插入（模拟 ⌘V）。

        请在「系统设置 → 隐私与安全性 → 辅助功能」中：
        1. 删除列表里旧的 ClipStack 条目（如果有）
        2. 重新勾选当前这个应用：
        \(appPath)

        每次重新安装/编译后，macOS 可能把它当成新应用，需要重新授权。
        """
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "知道了")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}

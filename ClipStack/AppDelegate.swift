import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var historyPanel: HistoryPanelController?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private let onboardingController = OnboardingWindowController()
    private var settingsWindowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Stay a menu-bar agent by default; promote to regular only while Settings is open.
        NSApp.setActivationPolicy(.accessory)

        appState.load()

        historyPanel = HistoryPanelController(appState: appState)
        clipboardMonitor = ClipboardMonitor(appState: appState)
        hotkeyManager = HotkeyManager(appState: appState, historyPanel: historyPanel!)

        clipboardMonitor?.start()
        hotkeyManager?.register()

        appState.onHotkeySettingsChanged = { [weak self] in
            self?.hotkeyManager?.reregisterHotkeys()
        }

        appState.onInsertItem = { [weak self] item, asPlainText in
            Task { @MainActor in
                await self?.insertItem(item, asPlainText: asPlainText)
            }
        }

        appState.onCopyItem = { [weak self] item in
            self?.copyItemToPasteboard(item)
        }

        appState.onTogglePanel = { [weak self] in
            self?.historyPanel?.toggle()
        }

        appState.onClosePanel = { [weak self] in
            self?.historyPanel?.hide()
        }

        appState.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        observeSettingsWindowClose()
        onboardingController.showIfNeeded(appState: appState)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let settingsWindowCloseObserver {
            NotificationCenter.default.removeObserver(settingsWindowCloseObserver)
        }
        appState.saveImmediately()
    }

    /// Agent apps hide Dock/menu; temporarily become a normal app so Settings is obvious.
    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let settingsSelector = Selector(("showSettingsWindow:"))
        let preferencesSelector = Selector(("showPreferencesWindow:"))
        if NSApp.responds(to: settingsSelector) {
            NSApp.sendAction(settingsSelector, to: nil, from: nil)
        } else if NSApp.responds(to: preferencesSelector) {
            NSApp.sendAction(preferencesSelector, to: nil, from: nil)
        }

        DispatchQueue.main.async { [weak self] in
            self?.bringStandardWindowsForward()
        }
        // Settings window may be created on the next run-loop turn.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.bringStandardWindowsForward()
        }
    }

    private func observeSettingsWindowClose() {
        settingsWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Defer until after the closing window is gone from NSApp.windows.
            DispatchQueue.main.async {
                self?.restoreAccessoryPolicyIfNeeded()
            }
        }
    }

    private func restoreAccessoryPolicyIfNeeded() {
        let hasStandardWindow = NSApp.windows.contains { isStandardAppWindow($0) && $0.isVisible }
        guard !hasStandardWindow else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    private func bringStandardWindowsForward() {
        for window in NSApp.windows where isStandardAppWindow(window) {
            window.collectionBehavior.insert(.moveToActiveSpace)
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Titled app windows (Settings / onboarding), not the floating history NSPanel.
    private func isStandardAppWindow(_ window: NSWindow) -> Bool {
        guard !(window is NSPanel) else { return false }
        guard window.styleMask.contains(.titled) else { return false }
        // Status-item / menu-bar chrome sometimes appears as a tiny untitled-ish window.
        guard window.contentView != nil else { return false }
        return true
    }

    private func insertItem(_ item: ClipboardItem, asPlainText: Bool) async {
        clipboardMonitor?.performingInternalWrite {
            ClipboardInsertService.writeToClipboard(item, asPlainText: asPlainText)
        }

        await historyPanel?.hideAndRestorePreviousApp()
        _ = ClipboardInsertService.paste(showingPromptIfNeeded: true)
    }

    private func copyItemToPasteboard(_ item: ClipboardItem) {
        clipboardMonitor?.performingInternalWrite {
            ClipboardInsertService.writeToClipboard(item)
        }
        appState.moveItemToFront(item)
        appState.showCopiedToast()
    }
}

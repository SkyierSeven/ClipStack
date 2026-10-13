import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var historyPanel: HistoryPanelController?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private let onboardingController = OnboardingWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
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

        appState.onTogglePanel = { [weak self] in
            self?.historyPanel?.toggle()
        }

        appState.onClosePanel = { [weak self] in
            self?.historyPanel?.hide()
        }

        onboardingController.showIfNeeded(appState: appState)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.saveImmediately()
    }

    private func insertItem(_ item: ClipboardItem, asPlainText: Bool) async {
        clipboardMonitor?.performingInternalWrite {
            ClipboardInsertService.writeToClipboard(item, asPlainText: asPlainText)
        }

        await historyPanel?.hideAndRestorePreviousApp()
        _ = ClipboardInsertService.paste(showingPromptIfNeeded: true)
    }
}

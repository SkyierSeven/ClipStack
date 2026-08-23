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

        appState.onInsertItem = { [weak self] item in
            ClipboardInsertService.insert(item)
            self?.historyPanel?.hide()
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
}

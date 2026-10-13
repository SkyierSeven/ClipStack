import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var historyPanel: HistoryPanelController?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private let onboardingController = OnboardingWindowController()
    private let settingsWindowController = SettingsWindowController()
    private weak var pauseMenuItem: NSMenuItem?

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

        settingsWindowController.onClose = { [weak self] in
            self?.restoreAccessoryPolicyIfNeeded()
        }

        onboardingController.showIfNeeded(appState: appState)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.saveImmediately()
    }

    /// Agent apps hide Dock/menu; temporarily become a normal app so Settings is obvious.
    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController.show(appState: appState)
        NSApp.activate(ignoringOtherApps: true)
        installMinimalMainMenu()
        // Menu bar may rebuild one turn after activation-policy changes.
        DispatchQueue.main.async { [weak self] in
            self?.installMinimalMainMenu()
        }
    }

    private func restoreAccessoryPolicyIfNeeded() {
        // Keep Dock/menu while onboarding or settings is still visible.
        if settingsWindowController.isVisible { return }
        let hasOnboarding = NSApp.windows.contains {
            $0.title == "ClipStack 引导" && $0.isVisible
        }
        if hasOnboarding { return }
        NSApp.setActivationPolicy(.accessory)
    }

    /// Replace the stock app menu with Pause / Open Panel / Quit, and keep Help.
    func installMinimalMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "ClipStack")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let pauseItem = NSMenuItem(
            title: pauseMenuTitle,
            action: #selector(menuTogglePause),
            keyEquivalent: ""
        )
        pauseItem.target = self
        appMenu.addItem(pauseItem)
        pauseMenuItem = pauseItem

        let openPanelItem = NSMenuItem(
            title: "打开面板",
            action: #selector(menuOpenPanel),
            keyEquivalent: ""
        )
        openPanelItem.target = self
        appMenu.addItem(openPanelItem)

        appMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(menuQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        appMenu.addItem(quitItem)

        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "帮助")
        helpMenuItem.submenu = helpMenu
        let helpItem = NSMenuItem(
            title: "ClipStack 帮助",
            action: #selector(menuOpenHelp),
            keyEquivalent: ""
        )
        helpItem.target = self
        helpMenu.addItem(helpItem)
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private var pauseMenuTitle: String {
        appState.isMonitoringPaused ? "恢复" : "暂停"
    }

    @objc private func menuTogglePause() {
        appState.isMonitoringPaused.toggle()
        appState.save()
        pauseMenuItem?.title = pauseMenuTitle
    }

    @objc private func menuOpenPanel() {
        historyPanel?.show()
    }

    @objc private func menuQuit() {
        appState.save()
        NSApp.terminate(nil)
    }

    @objc private func menuOpenHelp() {
        guard let url = URL(string: "https://github.com/SkyierSeven/ClipStack#readme") else { return }
        NSWorkspace.shared.open(url)
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

import SwiftUI

struct MenuBarMenuView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button("打开历史面板 (\(appState.panelHotkeyDisplay))") {
            appState.onTogglePanel?()
        }

        Button(appState.isMonitoringPaused ? "恢复记录" : "暂停记录") {
            appState.isMonitoringPaused.toggle()
            appState.save()
        }

        Divider()

        Button("设置…") {
            appState.onOpenSettings?()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("退出 ClipStack") {
            appState.save()
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

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

        SettingsLink {
            Text("设置…")
        }

        Divider()

        Button("退出 ClipStack") {
            appState.save()
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

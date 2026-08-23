import SwiftUI

@main
struct ClipStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("ClipStack", systemImage: "doc.on.clipboard") {
            MenuBarMenuView()
                .environment(appDelegate.appState)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(appDelegate.appState)
        }
    }
}

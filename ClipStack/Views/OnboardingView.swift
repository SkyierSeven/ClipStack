import AppKit
import SwiftUI

@MainActor
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    var onComplete: (() -> Void)?
    @State private var step = 0
    @State private var launchAtLogin = true

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case 0: welcomeStep
                case 1: accessibilityStep
                case 2: shortcutStep
                default: finishStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                if step > 0 {
                    Button("上一步") { step -= 1 }
                }
                Spacer()
                if step < 3 {
                    Button("下一步") { step += 1 }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("开始使用") { finish() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 520, height: 400)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("欢迎使用 ClipStack")
                .font(.title2.bold())
            Text("免费、开源、本地的剪贴板管理器。\n复制的内容会自动保存在本机，不会上传云端。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }

    private var accessibilityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("辅助功能权限", systemImage: "hand.raised.fill")
                .font(.title3.bold())
            Text("自动插入内容需要辅助功能权限。重新编译或替换应用后，macOS 可能要求你重新勾选一次。")
                .foregroundStyle(.secondary)
            HStack {
                Image(systemName: ClipboardInsertService.isTrusted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(ClipboardInsertService.isTrusted ? .green : .orange)
                Text(ClipboardInsertService.isTrusted ? "已授权" : "尚未授权")
                Spacer()
                if !ClipboardInsertService.isTrusted {
                    Button("请求权限") {
                        _ = ClipboardInsertService.requestAccessibilityPermission(prompt: true)
                    }
                    Button("打开系统设置") {
                        ClipboardInsertService.openAccessibilitySettings()
                    }
                }
            }
            .padding()
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            Text(Bundle.main.bundlePath)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            _ = ClipboardInsertService.requestAccessibilityPermission(prompt: false)
        }
    }

    private var shortcutStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("全局快捷键", systemImage: "command")
                .font(.title3.bold())
            Text("点击录制框，按下你喜欢的组合键打开历史面板。")
                .foregroundStyle(.secondary)
            ShortcutRecorderView(
                title: "打开面板",
                hotkey: panelHotkeyBinding,
                onChange: {}
            )
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var finishStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("准备就绪", systemImage: "sparkles")
                .font(.title3.bold())
            Toggle("登录时启动 ClipStack", isOn: $launchAtLogin)
            Text("应用运行在菜单栏，可通过快捷键随时呼出历史面板。")
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private var panelHotkeyBinding: Binding<StoredHotkey> {
        Binding(
            get: { appState.panelHotkey },
            set: { appState.updatePanelHotkey($0) }
        )
    }

    @MainActor
    private func finish() {
        appState.completeOnboarding(launchAtLogin: launchAtLogin)
        onComplete?()
    }
}

@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?

    func showIfNeeded(appState: AppState) {
        guard !appState.hasCompletedOnboarding else { return }
        let content = OnboardingView(onComplete: { [weak self] in
            self?.window?.close()
            self?.window = nil
            NSApp.setActivationPolicy(.accessory)
        })
            .environment(appState)

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "ClipStack 引导"
        panel.contentView = NSHostingView(rootView: content)
        panel.center()
        panel.isReleasedWhenClosed = false
        // Match Settings: show Dock + menu while a standard window is open.
        NSApp.setActivationPolicy(.regular)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
    }
}

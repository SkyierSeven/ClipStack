import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralSettingsPane()
                .tabItem { Label("通用", systemImage: "gearshape") }

            PrivacySettingsPane()
                .tabItem { Label("隐私", systemImage: "hand.raised") }

            ShortcutsSettingsPane()
                .tabItem { Label("快捷键", systemImage: "command") }
        }
        .frame(minWidth: 500, idealWidth: 540, minHeight: 420, idealHeight: 480)
    }
}

// MARK: - General

private struct GeneralSettingsPane: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                Toggle("暂停记录剪贴板", isOn: pauseBinding)
                Toggle("登录时启动", isOn: launchAtLoginBinding)
            }

            Section {
                Toggle("无限保留历史", isOn: unlimitedHistoryBinding)

                if !appState.isHistoryUnlimited {
                    LabeledContent("保留上限") {
                        HStack(spacing: 12) {
                            Text(appState.historyLimitDisplayText)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 56, alignment: .trailing)

                            Stepper("", value: historyLimitBinding, in: 50...5000, step: 50)
                                .labelsHidden()
                        }
                    }
                }
            } footer: {
                Text("数据保存在本机 Application Support/ClipStack，不会上传云端。开启无限后，历史记录只受磁盘空间限制。")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var pauseBinding: Binding<Bool> {
        Binding(
            get: { appState.isMonitoringPaused },
            set: { newValue in
                appState.isMonitoringPaused = newValue
                appState.save()
            }
        )
    }

    private var unlimitedHistoryBinding: Binding<Bool> {
        Binding(
            get: { appState.isHistoryUnlimited },
            set: { appState.setHistoryUnlimited($0) }
        )
    }

    private var historyLimitBinding: Binding<Int> {
        Binding(
            get: { appState.historyLimit },
            set: { appState.updateFiniteHistoryLimit($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.launchAtLoginEnabled },
            set: { appState.setLaunchAtLogin($0) }
        )
    }
}

// MARK: - Privacy

private struct PrivacySettingsPane: View {
    @Environment(AppState.self) private var appState

    private var excludedApps: [AppIdentity] {
        appState.excludedBundleIDs
            .map { AppBundleResolver.identity(for: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section {
                if excludedApps.isEmpty {
                    Text("暂无排除应用")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(excludedApps) { app in
                        ExcludedAppRow(identity: app) {
                            appState.excludedBundleIDs.remove(app.bundleID)
                            appState.save()
                        }
                    }
                }
            } header: {
                Text("忽略以下应用的复制内容")
            }

            Section {
                Button {
                    addApplicationFromPicker()
                } label: {
                    Label("选择应用…", systemImage: "plus.app")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func addApplicationFromPicker() {
        guard let bundleID = AppPicker.pickApplication() else { return }
        appState.excludedBundleIDs.insert(bundleID)
        appState.save()
    }
}

// MARK: - Shortcuts

private struct ShortcutsSettingsPane: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                ShortcutRecorderView(
                    title: "打开历史面板",
                    hotkey: panelHotkeyBinding,
                    onChange: {}
                )
                .padding(.vertical, 4)
            } header: {
                Text("历史面板")
            }

            Section {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledContent("数字快捷键") {
                        Text(appState.slotHotkeyDisplay)
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Toggle("插入最近 9 条需要按住 ⌥", isOn: slotHotkeyBinding)

                    Text("开启后使用 ⌘⌥1–9，与打开面板的快捷键拉开距离，减少误触。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } header: {
                Text("数字快捷键")
            } footer: {
                Text("快捷键全局生效。修改后会立即应用，若与其他应用冲突请更换组合。")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var panelHotkeyBinding: Binding<StoredHotkey> {
        Binding(
            get: { appState.panelHotkey },
            set: { appState.updatePanelHotkey($0) }
        )
    }

    private var slotHotkeyBinding: Binding<Bool> {
        Binding(
            get: { appState.slotHotkeyUsesOption },
            set: { appState.setSlotHotkeyUsesOption($0) }
        )
    }
}

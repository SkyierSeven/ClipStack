import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyManager {
    private let appState: AppState
    private let historyPanel: HistoryPanelController
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    private var isHandlerInstalled = false

    init(appState: AppState, historyPanel: HistoryPanelController) {
        self.appState = appState
        self.historyPanel = historyPanel
    }

    func register() {
        installHandlerIfNeeded()
        reregisterHotkeys()
    }

    func reregisterHotkeys() {
        unregisterHotkeys()
        registerHotkeys()
    }

    private func installHandlerIfNeeded() {
        guard !isHandlerInstalled else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.handleHotkey(event: event)
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        isHandlerInstalled = true
    }

    private func registerHotkeys() {
        let panel = appState.panelHotkey
        registerHotkey(keyCode: panel.keyCode, modifiers: panel.carbonModifiers, id: 1)

        let slotHotkeyModifiers: UInt32 = appState.slotHotkeyUsesOption
            ? UInt32(cmdKey | optionKey)
            : UInt32(cmdKey)

        for index in 0..<9 {
            registerHotkey(keyCode: UInt32(kVK_ANSI_1 + index), modifiers: slotHotkeyModifiers, id: UInt32(10 + index))
        }
    }

    private func registerHotkey(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C5053), id: id) // CLPS
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        hotKeyRefs.append(ref)
    }

    private func unregisterHotkeys() {
        for ref in hotKeyRefs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
    }

    private func handleHotkey(event: EventRef?) {
        guard let event else { return }
        var hotKeyID = EventHotKeyID()
        GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        switch hotKeyID.id {
        case 1:
            historyPanel.toggle()
        case 10...18:
            let index = Int(hotKeyID.id - 10)
            appState.insertItem(at: index)
        default:
            break
        }
    }
}

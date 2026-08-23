import AppKit
import SwiftUI

struct ShortcutRecorderView: View {
    let title: String
    @Binding var hotkey: StoredHotkey
    let onChange: () -> Void

    @State private var isRecording = false
    @State private var savedHotkey: StoredHotkey?

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(width: 132, alignment: .leading)

            Button {
                if isRecording {
                    cancelRecording()
                } else {
                    savedHotkey = hotkey
                    isRecording = true
                }
            } label: {
                Group {
                    if isRecording {
                        Text("请按下快捷键…")
                    } else {
                        HotkeyLabel(parts: hotkey.displayParts)
                    }
                }
                .font(.body.monospaced())
                .foregroundStyle(isRecording ? .primary : .secondary)
                .frame(minWidth: 120, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isRecording ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .background {
            if isRecording {
                KeyCaptureRepresentable(
                    onCapture: { event in
                        let captured = HotkeyDisplay.from(event: event)
                        guard captured.carbonModifiers != 0 else { return }
                        hotkey = captured
                        savedHotkey = nil
                        isRecording = false
                        onChange()
                    },
                    onCancel: cancelRecording
                )
                .frame(width: 0, height: 0)
            }
        }
        .onExitCommand {
            cancelRecording()
        }
    }

    private func cancelRecording() {
        guard isRecording else { return }
        if let savedHotkey {
            hotkey = savedHotkey
        }
        self.savedHotkey = nil
        isRecording = false
    }
}

private struct HotkeyLabel: View {
    let parts: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                Text(part)
            }
        }
    }
}

private struct KeyCaptureRepresentable: NSViewRepresentable {
    let onCapture: (NSEvent) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onCapture = onCapture
        view.onCancel = onCancel
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onCapture = onCapture
        nsView.onCancel = onCancel
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyCaptureView: NSView {
    var onCapture: ((NSEvent) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            onCancel?()
        }
        return resigned
    }

    override func keyDown(with event: NSEvent) {
        onCapture?(event)
    }
}

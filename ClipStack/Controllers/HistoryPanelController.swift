import AppKit
import SwiftUI

@MainActor
final class HistoryPanelController {
    private let appState: AppState
    private let panel: KeyablePanel
    private var isVisible = false

    init(appState: AppState) {
        self.appState = appState

        let contentView = HistoryView()
            .environment(appState)

        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: AppTheme.panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.title = "ClipStack"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.focusRingType = .none
        panel.contentView = hostingView
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let height = AppTheme.panelHeight + 24
        let targetFrame = NSRect(
            x: visibleFrame.minX + 12,
            y: visibleFrame.minY + 8,
            width: visibleFrame.width - 24,
            height: height
        )

        let startFrame = NSRect(
            x: targetFrame.minX,
            y: visibleFrame.minY - height,
            width: targetFrame.width,
            height: targetFrame.height
        )

        panel.setFrame(startFrame, display: true)
        panel.alphaValue = 0
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1
        }

        isVisible = true
        appState.selectFirstItemIfNeeded()
        focusSearchField()
        NSLog("[ClipStack] panel shown")
    }

    func hide() {
        guard let screen = NSScreen.main else {
            panel.orderOut(nil)
            isVisible = false
            return
        }

        let visibleFrame = screen.visibleFrame
        let current = panel.frame
        let endFrame = NSRect(
            x: current.minX,
            y: visibleFrame.minY - current.height,
            width: current.width,
            height: current.height
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(endFrame, display: true)
            panel.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
                self.isVisible = false
                NSLog("[ClipStack] panel hidden")
            }
        }
    }

    func focusSearchField() {
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.appState.shouldFocusSearch = true
        }
    }
}

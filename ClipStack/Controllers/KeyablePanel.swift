import AppKit
import QuickLookUI
import SwiftUI

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override var canBecomeMain: Bool { false }

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        true
    }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        QuickLookPreviewService.shared.prepareToControlPreviewPanel(panel)
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        QuickLookPreviewService.shared.finishControllingPreviewPanel(panel)
    }
}

/// Hosting view that never draws the system focus ring.
final class FocusRingDisabledHostingView<Content: View>: NSHostingView<Content> {
    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        focusRingType = .none
        disableFocusRings(in: self)
    }

    override func layout() {
        super.layout()
        disableFocusRings(in: self)
    }

    private func disableFocusRings(in view: NSView) {
        view.focusRingType = .none
        for subview in view.subviews {
            disableFocusRings(in: subview)
        }
    }
}

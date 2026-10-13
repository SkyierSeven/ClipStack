import SwiftUI

enum AppTheme {
    static let cardWidth: CGFloat = 168
    static let cardHeight: CGFloat = 196
    static let cardHeaderHeight: CGFloat = 34
    static let cardCorner: CGFloat = 14
    static let cardInnerCorner: CGFloat = 8
    static let cardSpacing: CGFloat = 14
    static let cardHoverScale: CGFloat = 1.04
    static let cardHoverLift: CGFloat = 8
    static let cardHoverOverflow: CGFloat = 14
    static let stripPadding: CGFloat = 20

    /// topBar + filter + paddings/spacings around the card strip.
    private static let panelChromeHeight: CGFloat = 14 + 30 + 8 + 28 + 8 + 16

    static var cardStripHeight: CGFloat {
        cardHeight + cardHoverOverflow * 2
    }

    /// Fits the dock chrome; no leftover height from the removed hint/action bar.
    static var panelHeight: CGFloat {
        panelChromeHeight + cardStripHeight
    }

    /// Dock chrome stays dark; cards follow system appearance.
    static let dockBackground = Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.82)
    static let mutedText = Color.white.opacity(0.62)
    /// Guide / instructional accent (blue).
    static let accent = Color(red: 0.35, green: 0.62, blue: 1.0)
    /// Pinned item accent (amber) — intentionally different from guide blue.
    static let pinAccent = Color(red: 0.92, green: 0.62, blue: 0.18)

    static func colors(for scheme: ColorScheme) -> CardColors {
        scheme == .dark ? .dark : .light
    }
}

struct CardColors {
    let background: Color
    let border: Color
    let selectedBorder: Color
    let pinnedBorder: Color
    let shadow: Color
    let primaryText: Color
    let secondaryText: Color
    let previewText: Color
    let previewFill: Color
    let hintBarFill: Color
    let hintBarDivider: Color
    let keycapFill: Color
    let keycapStroke: Color

    static let light = CardColors(
        background: Color(red: 0.98, green: 0.98, blue: 0.99),
        border: Color.black.opacity(0.08),
        selectedBorder: Color.black.opacity(0.22),
        pinnedBorder: Color(red: 0.88, green: 0.58, blue: 0.12).opacity(0.85),
        shadow: Color.black.opacity(0.22),
        primaryText: Color(red: 0.16, green: 0.16, blue: 0.18),
        secondaryText: Color(red: 0.42, green: 0.42, blue: 0.45),
        previewText: Color(red: 0.22, green: 0.22, blue: 0.26),
        previewFill: Color.black.opacity(0.04),
        hintBarFill: Color(red: 0.93, green: 0.93, blue: 0.95),
        hintBarDivider: Color.black.opacity(0.08),
        keycapFill: Color(red: 0.88, green: 0.88, blue: 0.90),
        keycapStroke: Color(red: 0.72, green: 0.72, blue: 0.74)
    )

    static let dark = CardColors(
        background: Color(red: 0.18, green: 0.18, blue: 0.20),
        border: Color.white.opacity(0.10),
        selectedBorder: Color.white.opacity(0.34),
        pinnedBorder: Color(red: 0.96, green: 0.72, blue: 0.28).opacity(0.9),
        shadow: Color.black.opacity(0.45),
        primaryText: Color(red: 0.94, green: 0.94, blue: 0.96),
        secondaryText: Color(red: 0.70, green: 0.70, blue: 0.74),
        previewText: Color(red: 0.86, green: 0.86, blue: 0.90),
        previewFill: Color.white.opacity(0.06),
        hintBarFill: Color(red: 0.14, green: 0.14, blue: 0.16),
        hintBarDivider: Color.white.opacity(0.08),
        keycapFill: Color(red: 0.26, green: 0.26, blue: 0.29),
        keycapStroke: Color(red: 0.42, green: 0.42, blue: 0.46)
    )
}

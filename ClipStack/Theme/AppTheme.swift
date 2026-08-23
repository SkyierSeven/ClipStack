import SwiftUI

enum AppTheme {
    static let cardWidth: CGFloat = 168
    static let cardHeight: CGFloat = 196
    static let cardHeaderHeight: CGFloat = 34
    static let cardPreviewHeight: CGFloat = 104
    static let cardActionHeight: CGFloat = 34
    static let cardCorner: CGFloat = 14
    static let cardInnerCorner: CGFloat = 8
    static let cardSpacing: CGFloat = 14
    static let cardHoverScale: CGFloat = 1.04
    static let cardHoverLift: CGFloat = 8
    static let cardHoverOverflow: CGFloat = 14
    static let stripPadding: CGFloat = 20

    static var cardStripHeight: CGFloat {
        cardHeight + cardHoverOverflow * 2
    }

    static var panelHeight: CGFloat {
        58 + cardStripHeight + 18 + 36
    }

    static let dockBackground = Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.82)
    static let cardBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let cardBorder = Color.white.opacity(0.55)
    static let cardShadow = Color.black.opacity(0.22)
    static let mutedText = Color.white.opacity(0.62)
    static let accent = Color(red: 0.35, green: 0.62, blue: 1.0)
}

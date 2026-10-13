import Foundation

struct PersistedData: Codable {
    var items: [ClipboardItem]
    var pinboards: [Pinboard]
    var excludedBundleIDs: [String]
    var historyLimit: Int
    var savedFiniteHistoryLimit: Int?
    var isMonitoringPaused: Bool
    var panelHotkeyKeyCode: UInt32?
    var panelHotkeyModifiers: UInt32?
    var hasCompletedOnboarding: Bool?
    var launchAtLoginEnabled: Bool?
    var hidePanelAfterCopy: Bool?

    static let unlimitedHistoryLimit = 0

    static let `default` = PersistedData(
        items: [],
        pinboards: [Pinboard(name: "默认")],
        excludedBundleIDs: [],
        historyLimit: unlimitedHistoryLimit,
        savedFiniteHistoryLimit: 500,
        isMonitoringPaused: false,
        panelHotkeyKeyCode: StoredHotkey.defaultPanel.keyCode,
        panelHotkeyModifiers: StoredHotkey.defaultPanel.carbonModifiers,
        hasCompletedOnboarding: false,
        launchAtLoginEnabled: false,
        hidePanelAfterCopy: true
    )

    private enum CodingKeys: String, CodingKey {
        case items, pinboards, stackItemIDs, excludedBundleIDs, historyLimit
        case savedFiniteHistoryLimit, isMonitoringPaused
        case panelHotkeyKeyCode, panelHotkeyModifiers
        case hasCompletedOnboarding, launchAtLoginEnabled, hidePanelAfterCopy
    }

    init(
        items: [ClipboardItem],
        pinboards: [Pinboard],
        excludedBundleIDs: [String],
        historyLimit: Int,
        savedFiniteHistoryLimit: Int?,
        isMonitoringPaused: Bool,
        panelHotkeyKeyCode: UInt32?,
        panelHotkeyModifiers: UInt32?,
        hasCompletedOnboarding: Bool?,
        launchAtLoginEnabled: Bool?,
        hidePanelAfterCopy: Bool?
    ) {
        self.items = items
        self.pinboards = pinboards
        self.excludedBundleIDs = excludedBundleIDs
        self.historyLimit = historyLimit
        self.savedFiniteHistoryLimit = savedFiniteHistoryLimit
        self.isMonitoringPaused = isMonitoringPaused
        self.panelHotkeyKeyCode = panelHotkeyKeyCode
        self.panelHotkeyModifiers = panelHotkeyModifiers
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.hidePanelAfterCopy = hidePanelAfterCopy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([ClipboardItem].self, forKey: .items)
        pinboards = try container.decode([Pinboard].self, forKey: .pinboards)
        // Legacy insert-queue IDs are ignored after the feature was removed.
        _ = try container.decodeIfPresent([UUID].self, forKey: .stackItemIDs)
        excludedBundleIDs = try container.decode([String].self, forKey: .excludedBundleIDs)
        historyLimit = try container.decode(Int.self, forKey: .historyLimit)
        savedFiniteHistoryLimit = try container.decodeIfPresent(Int.self, forKey: .savedFiniteHistoryLimit)
        isMonitoringPaused = try container.decode(Bool.self, forKey: .isMonitoringPaused)
        panelHotkeyKeyCode = try container.decodeIfPresent(UInt32.self, forKey: .panelHotkeyKeyCode)
        panelHotkeyModifiers = try container.decodeIfPresent(UInt32.self, forKey: .panelHotkeyModifiers)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled)
        hidePanelAfterCopy = try container.decodeIfPresent(Bool.self, forKey: .hidePanelAfterCopy)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(pinboards, forKey: .pinboards)
        try container.encode(excludedBundleIDs, forKey: .excludedBundleIDs)
        try container.encode(historyLimit, forKey: .historyLimit)
        try container.encodeIfPresent(savedFiniteHistoryLimit, forKey: .savedFiniteHistoryLimit)
        try container.encode(isMonitoringPaused, forKey: .isMonitoringPaused)
        try container.encodeIfPresent(panelHotkeyKeyCode, forKey: .panelHotkeyKeyCode)
        try container.encodeIfPresent(panelHotkeyModifiers, forKey: .panelHotkeyModifiers)
        try container.encodeIfPresent(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encodeIfPresent(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encodeIfPresent(hidePanelAfterCopy, forKey: .hidePanelAfterCopy)
    }
}

import Foundation

struct PersistedData: Codable {
    var items: [ClipboardItem]
    var pinboards: [Pinboard]
    var stackItemIDs: [UUID]
    var excludedBundleIDs: [String]
    var historyLimit: Int
    var savedFiniteHistoryLimit: Int?
    var isMonitoringPaused: Bool
    var panelHotkeyKeyCode: UInt32?
    var panelHotkeyModifiers: UInt32?
    var slotHotkeyUsesOption: Bool?
    var hasCompletedOnboarding: Bool?
    var launchAtLoginEnabled: Bool?

    static let unlimitedHistoryLimit = 0

    static let `default` = PersistedData(
        items: [],
        pinboards: [Pinboard(name: "默认")],
        stackItemIDs: [],
        excludedBundleIDs: [],
        historyLimit: unlimitedHistoryLimit,
        savedFiniteHistoryLimit: 500,
        isMonitoringPaused: false,
        panelHotkeyKeyCode: StoredHotkey.defaultPanel.keyCode,
        panelHotkeyModifiers: StoredHotkey.defaultPanel.carbonModifiers,
        slotHotkeyUsesOption: false,
        hasCompletedOnboarding: false,
        launchAtLoginEnabled: false
    )

    private enum CodingKeys: String, CodingKey {
        case items, pinboards, stackItemIDs, excludedBundleIDs, historyLimit
        case savedFiniteHistoryLimit, isMonitoringPaused
        case panelHotkeyKeyCode, panelHotkeyModifiers
        case slotHotkeyUsesOption = "quickPasteUsesOption"
        case hasCompletedOnboarding, launchAtLoginEnabled
    }

    init(
        items: [ClipboardItem],
        pinboards: [Pinboard],
        stackItemIDs: [UUID],
        excludedBundleIDs: [String],
        historyLimit: Int,
        savedFiniteHistoryLimit: Int?,
        isMonitoringPaused: Bool,
        panelHotkeyKeyCode: UInt32?,
        panelHotkeyModifiers: UInt32?,
        slotHotkeyUsesOption: Bool?,
        hasCompletedOnboarding: Bool?,
        launchAtLoginEnabled: Bool?
    ) {
        self.items = items
        self.pinboards = pinboards
        self.stackItemIDs = stackItemIDs
        self.excludedBundleIDs = excludedBundleIDs
        self.historyLimit = historyLimit
        self.savedFiniteHistoryLimit = savedFiniteHistoryLimit
        self.isMonitoringPaused = isMonitoringPaused
        self.panelHotkeyKeyCode = panelHotkeyKeyCode
        self.panelHotkeyModifiers = panelHotkeyModifiers
        self.slotHotkeyUsesOption = slotHotkeyUsesOption
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.launchAtLoginEnabled = launchAtLoginEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([ClipboardItem].self, forKey: .items)
        pinboards = try container.decode([Pinboard].self, forKey: .pinboards)
        stackItemIDs = try container.decode([UUID].self, forKey: .stackItemIDs)
        excludedBundleIDs = try container.decode([String].self, forKey: .excludedBundleIDs)
        historyLimit = try container.decode(Int.self, forKey: .historyLimit)
        savedFiniteHistoryLimit = try container.decodeIfPresent(Int.self, forKey: .savedFiniteHistoryLimit)
        isMonitoringPaused = try container.decode(Bool.self, forKey: .isMonitoringPaused)
        panelHotkeyKeyCode = try container.decodeIfPresent(UInt32.self, forKey: .panelHotkeyKeyCode)
        panelHotkeyModifiers = try container.decodeIfPresent(UInt32.self, forKey: .panelHotkeyModifiers)
        slotHotkeyUsesOption = try container.decodeIfPresent(Bool.self, forKey: .slotHotkeyUsesOption)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(pinboards, forKey: .pinboards)
        try container.encode(stackItemIDs, forKey: .stackItemIDs)
        try container.encode(excludedBundleIDs, forKey: .excludedBundleIDs)
        try container.encode(historyLimit, forKey: .historyLimit)
        try container.encodeIfPresent(savedFiniteHistoryLimit, forKey: .savedFiniteHistoryLimit)
        try container.encode(isMonitoringPaused, forKey: .isMonitoringPaused)
        try container.encodeIfPresent(panelHotkeyKeyCode, forKey: .panelHotkeyKeyCode)
        try container.encodeIfPresent(panelHotkeyModifiers, forKey: .panelHotkeyModifiers)
        try container.encodeIfPresent(slotHotkeyUsesOption, forKey: .slotHotkeyUsesOption)
        try container.encodeIfPresent(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encodeIfPresent(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
    }
}

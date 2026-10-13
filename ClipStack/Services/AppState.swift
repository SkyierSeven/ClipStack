import Foundation
import Observation

enum HistoryTab: String, CaseIterable, Identifiable {
    case history = "历史"
    case pinboards = "固定板"
    case stack = "插入队列"

    var id: String { rawValue }
}

@MainActor
@Observable
final class AppState {
    var items: [ClipboardItem] = []
    var pinboards: [Pinboard] = [Pinboard(name: "默认")]
    var stackItemIDs: [UUID] = []
    var excludedBundleIDs: Set<String> = []
    var historyLimit: Int = PersistedData.unlimitedHistoryLimit
    var savedFiniteHistoryLimit: Int = 500
    var isMonitoringPaused = false
    var hasCompletedOnboarding = false
    var launchAtLoginEnabled = false
    var hidePanelAfterCopy = true

    var isHistoryUnlimited: Bool {
        historyLimit == PersistedData.unlimitedHistoryLimit
    }

    var historyLimitDisplayText: String {
        isHistoryUnlimited ? "无限" : "\(historyLimit) 条"
    }

    var searchQuery = ""
    var shouldFocusSearch = false
    var selectedTab: HistoryTab = .history
    var selectedPinboardID: UUID?
    var selectedContentFilter: ContentTypeFilter = .all
    var selectedItemID: UUID?

    var panelHotkey = StoredHotkey.defaultPanel

    var panelHotkeyDisplay: String {
        panelHotkey.displayString
    }

    var onInsertItem: ((ClipboardItem, Bool) -> Void)?
    var onCopyItem: ((ClipboardItem) -> Void)?
    var onTogglePanel: (() -> Void)?
    var onClosePanel: (() -> Void)?
    var onHotkeySettingsChanged: (() -> Void)?

    /// Non-nil while the “copied” toast should be visible.
    var copyToastToken: UUID?

    private let store = ClipboardStore()

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isFilteringByType: Bool {
        selectedContentFilter != .all
    }

    var parsedSearchQuery: ClipboardSearch.ParsedQuery {
        ClipboardSearch.parse(searchQuery)
    }

    init() {
        selectedPinboardID = pinboards.first?.id
    }

    func load() {
        let data = store.load()
        items = data.items
        pinboards = data.pinboards.isEmpty ? [Pinboard(name: "默认")] : data.pinboards
        stackItemIDs = data.stackItemIDs
        excludedBundleIDs = Set(data.excludedBundleIDs)
        historyLimit = data.historyLimit
        savedFiniteHistoryLimit = data.savedFiniteHistoryLimit
            ?? (data.historyLimit > 0 ? data.historyLimit : 500)
        isMonitoringPaused = data.isMonitoringPaused
        hasCompletedOnboarding = data.hasCompletedOnboarding ?? false
        launchAtLoginEnabled = data.launchAtLoginEnabled ?? LaunchAtLoginService.isEnabled
        hidePanelAfterCopy = data.hidePanelAfterCopy ?? true
        if let keyCode = data.panelHotkeyKeyCode, let modifiers = data.panelHotkeyModifiers {
            panelHotkey = StoredHotkey(keyCode: keyCode, carbonModifiers: modifiers)
        }
        selectedPinboardID = pinboards.first?.id
    }

    func save() {
        store.scheduleSave(buildPersistedData())
    }

    func saveImmediately() {
        store.saveImmediately(buildPersistedData())
    }

    private func buildPersistedData() -> PersistedData {
        PersistedData(
            items: items,
            pinboards: pinboards,
            stackItemIDs: stackItemIDs,
            excludedBundleIDs: Array(excludedBundleIDs).sorted(),
            historyLimit: historyLimit,
            savedFiniteHistoryLimit: savedFiniteHistoryLimit,
            isMonitoringPaused: isMonitoringPaused,
            panelHotkeyKeyCode: panelHotkey.keyCode,
            panelHotkeyModifiers: panelHotkey.carbonModifiers,
            hasCompletedOnboarding: hasCompletedOnboarding,
            launchAtLoginEnabled: launchAtLoginEnabled,
            hidePanelAfterCopy: hidePanelAfterCopy
        )
    }

    var currentDisplayItems: [ClipboardItem] {
        switch selectedTab {
        case .history:
            if isSearching { return applyContentFilter(to: searchResults) }
            return applyContentFilter(to: items.filter { $0.pinboardID == nil })
        case .pinboards:
            if isSearching { return applyContentFilter(to: searchResults) }
            guard let selectedPinboardID else { return [] }
            return applyContentFilter(to: items.filter { $0.pinboardID == selectedPinboardID })
        case .stack:
            if isSearching { return applyContentFilter(to: searchResults) }
            let stack = stackItemIDs.compactMap { id in items.first { $0.id == id } }
            return applyContentFilter(to: stack)
        }
    }

    var filteredHistoryItems: [ClipboardItem] {
        if isSearching { return applyContentFilter(to: searchResults) }
        return applyContentFilter(to: items.filter { $0.pinboardID == nil })
    }

    var pinnedItems: [ClipboardItem] {
        if isSearching { return applyContentFilter(to: searchResults) }
        guard let selectedPinboardID else { return [] }
        return applyContentFilter(to: items.filter { $0.pinboardID == selectedPinboardID })
    }

    var stackItems: [ClipboardItem] {
        if isSearching { return applyContentFilter(to: searchResults) }
        let stack = stackItemIDs.compactMap { id in items.first { $0.id == id } }
        return applyContentFilter(to: stack)
    }

    var searchResults: [ClipboardItem] {
        let query = parsedSearchQuery
        guard !query.raw.isEmpty else { return [] }

        return items
            .filter { item in
                let pinboardName = pinboardName(for: item.pinboardID)
                return ClipboardSearch.matches(item: item, query: query, pinboardName: pinboardName)
            }
            .sorted { lhs, rhs in
                let lhsScore = ClipboardSearch.score(
                    item: lhs,
                    query: query,
                    pinboardName: pinboardName(for: lhs.pinboardID)
                )
                let rhsScore = ClipboardSearch.score(
                    item: rhs,
                    query: query,
                    pinboardName: pinboardName(for: rhs.pinboardID)
                )
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                return lhs.createdAt > rhs.createdAt
            }
    }

    var searchResultCount: Int {
        searchResults.count
    }

    func clearSearch() {
        searchQuery = ""
    }

    func selectFirstItemIfNeeded() {
        let list = currentDisplayItems
        if list.isEmpty {
            selectedItemID = nil
        } else if selectedItemID == nil || !list.contains(where: { $0.id == selectedItemID }) {
            selectedItemID = list.first?.id
        }
    }

    func moveSelection(offset: Int) {
        let list = currentDisplayItems
        guard !list.isEmpty else { return }
        guard let currentID = selectedItemID,
              let index = list.firstIndex(where: { $0.id == currentID }) else {
            selectedItemID = list.first?.id
            return
        }
        let next = min(max(index + offset, 0), list.count - 1)
        selectedItemID = list[next].id
    }

    func insertSelectedItem() {
        guard let selectedItemID,
              let item = currentDisplayItems.first(where: { $0.id == selectedItemID }) else { return }
        onInsertItem?(item, false)
    }

    func insertItem(_ item: ClipboardItem, asPlainText: Bool = false) {
        onInsertItem?(item, asPlainText)
    }

    func copySelectedItem() {
        guard let selectedItemID,
              let item = currentDisplayItems.first(where: { $0.id == selectedItemID }) else { return }
        copyItem(item)
    }

    func copyItem(_ item: ClipboardItem) {
        onCopyItem?(item)
    }

    func moveItemToFront(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let moved = items.remove(at: index)
        items.insert(moved, at: 0)
        selectedItemID = moved.id
        save()
    }

    func showCopiedToast() {
        let token = UUID()
        copyToastToken = token
        let shouldHidePanel = hidePanelAfterCopy
        Task { @MainActor in
            if shouldHidePanel {
                try? await Task.sleep(nanoseconds: 550_000_000)
                if copyToastToken == token {
                    copyToastToken = nil
                    onClosePanel?()
                }
            } else {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                if copyToastToken == token {
                    copyToastToken = nil
                }
            }
        }
    }

    func previewSelectedItem() {
        QuickLookPreviewService.shared.previewSelectedItem(from: self)
    }

    func previewItem(_ item: ClipboardItem) {
        QuickLookPreviewService.shared.preview(item)
    }

    func deleteSelectedItem() {
        guard let selectedItemID,
              let item = currentDisplayItems.first(where: { $0.id == selectedItemID }) else { return }
        deleteItem(item)
        selectFirstItemIfNeeded()
    }

    func updatePanelHotkey(_ hotkey: StoredHotkey) {
        guard hotkey.isValidPanelHotkey else { return }
        panelHotkey = hotkey
        save()
        onHotkeySettingsChanged?()
    }

    func completeOnboarding(launchAtLogin: Bool) {
        hasCompletedOnboarding = true
        launchAtLoginEnabled = launchAtLogin
        if launchAtLogin {
            _ = LaunchAtLoginService.setEnabled(true)
        }
        saveImmediately()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        _ = LaunchAtLoginService.setEnabled(enabled)
        save()
    }

    func applyContentFilter(to items: [ClipboardItem]) -> [ClipboardItem] {
        guard selectedContentFilter != .all else { return items }
        return items.filter { selectedContentFilter.matches($0) }
    }

    func pinboardName(for pinboardID: UUID?) -> String? {
        guard let pinboardID else { return nil }
        return pinboards.first { $0.id == pinboardID }?.name
    }

    func addItem(_ item: ClipboardItem) {
        var normalized = item.withPersistedImage()
        if let duplicateIndex = items.firstIndex(where: { isDuplicate($0, normalized) }) {
            items.remove(at: duplicateIndex)
        }
        items.insert(normalized, at: 0)
        trimHistory()
        save()

        if normalized.type == .image, let imageData = normalized.resolvedImageData {
            indexImageItem(itemID: normalized.id, imageData: imageData)
        }
    }

    func updateSearchIndex(for itemID: UUID, searchIndex: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].searchIndex = searchIndex
        save()
    }

    private func indexImageItem(itemID: UUID, imageData: Data) {
        Task {
            let indexedText = await ImageSearchIndexer.extractText(from: imageData)
            await MainActor.run {
                guard let indexedText else { return }
                updateSearchIndex(for: itemID, searchIndex: indexedText)
            }
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        if let imagePath = item.imagePath {
            ImageAssetStore.shared.deleteImage(relativePath: imagePath)
        }
        items.removeAll { $0.id == item.id }
        stackItemIDs.removeAll { $0 == item.id }
        for index in pinboards.indices {
            pinboards[index].itemIDs.removeAll { $0 == item.id }
        }
        save()
    }

    func clearHistory() {
        let toDelete = items.filter { $0.pinboardID == nil }
        for item in toDelete {
            if let imagePath = item.imagePath {
                ImageAssetStore.shared.deleteImage(relativePath: imagePath)
            }
        }
        items.removeAll { $0.pinboardID == nil }
        stackItemIDs.removeAll { id in !items.contains { $0.id == id } }
        save()
    }

    func pinItem(_ item: ClipboardItem, to pinboardID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].pinboardID = pinboardID
        if let pinboardIndex = pinboards.firstIndex(where: { $0.id == pinboardID }) {
            if !pinboards[pinboardIndex].itemIDs.contains(item.id) {
                pinboards[pinboardIndex].itemIDs.insert(item.id, at: 0)
            }
        }
        save()
    }

    func unpinItem(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let pinboardID = items[index].pinboardID
        items[index].pinboardID = nil
        if let pinboardID, let pinboardIndex = pinboards.firstIndex(where: { $0.id == pinboardID }) {
            pinboards[pinboardIndex].itemIDs.removeAll { $0 == item.id }
        }
        save()
    }

    func addPinboard(named name: String) {
        let board = Pinboard(name: name)
        pinboards.append(board)
        selectedPinboardID = board.id
        save()
    }

    func addToStack(_ item: ClipboardItem) {
        stackItemIDs.removeAll { $0 == item.id }
        stackItemIDs.append(item.id)
        save()
    }

    func removeFromStack(_ item: ClipboardItem) {
        stackItemIDs.removeAll { $0 == item.id }
        save()
    }

    func clearStack() {
        stackItemIDs.removeAll()
        save()
    }

    func insertStackSequentially() async {
        for id in stackItemIDs {
            guard let item = items.first(where: { $0.id == id }) else { continue }
            onInsertItem?(item, false)
            try? await Task.sleep(nanoseconds: 350_000_000)
        }
    }

    func toggleExcludedBundleID(_ bundleID: String) {
        if excludedBundleIDs.contains(bundleID) {
            excludedBundleIDs.remove(bundleID)
        } else {
            excludedBundleIDs.insert(bundleID)
        }
        save()
    }

    func setHistoryUnlimited(_ unlimited: Bool) {
        if unlimited {
            if historyLimit > 0 {
                savedFiniteHistoryLimit = historyLimit
            }
            historyLimit = PersistedData.unlimitedHistoryLimit
        } else {
            historyLimit = max(savedFiniteHistoryLimit, 50)
        }
        save()
    }

    func updateFiniteHistoryLimit(_ limit: Int) {
        let clamped = min(max(limit, 50), 5000)
        historyLimit = clamped
        savedFiniteHistoryLimit = clamped
        save()
    }

    private func trimHistory() {
        guard historyLimit > 0 else { return }
        let unpinnedCount = items.filter { $0.pinboardID == nil }.count
        guard unpinnedCount > historyLimit else { return }
        var removed = 0
        let target = unpinnedCount - historyLimit
        items = items.filter { item in
            if item.pinboardID != nil { return true }
            if removed < target {
                removed += 1
                if let imagePath = item.imagePath {
                    ImageAssetStore.shared.deleteImage(relativePath: imagePath)
                }
                stackItemIDs.removeAll { $0 == item.id }
                return false
            }
            return true
        }
    }

    private func isDuplicate(_ lhs: ClipboardItem, _ rhs: ClipboardItem) -> Bool {
        switch (lhs.type, rhs.type) {
        case (.text, .text), (.url, .url):
            return lhs.text == rhs.text
        case (.image, .image):
            if let lhsPath = lhs.imagePath, let rhsPath = rhs.imagePath {
                return lhsPath == rhsPath
            }
            return lhs.resolvedImageData == rhs.resolvedImageData
        case (.file, .file):
            return lhs.filePaths == rhs.filePaths
        default:
            return false
        }
    }
}

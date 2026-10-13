import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var items: [ClipboardItem] = []
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

    func load() {
        let data = store.load()
        items = data.items
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
            pinboards: [],
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
        filteredHistoryItems
    }

    var filteredHistoryItems: [ClipboardItem] {
        if isSearching { return applyContentFilter(to: searchResults) }
        return applyContentFilter(to: orderedHistoryItems(items))
    }

    var searchResults: [ClipboardItem] {
        let query = parsedSearchQuery
        guard !query.raw.isEmpty else { return [] }

        return orderedHistoryItems(
            items.filter { ClipboardSearch.matches(item: $0, query: query) }
        )
        .sorted { lhs, rhs in
            let lhsScore = ClipboardSearch.score(item: lhs, query: query)
            let rhsScore = ClipboardSearch.score(item: rhs, query: query)
            if lhsScore != rhsScore { return lhsScore > rhsScore }
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
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

    func addItem(_ item: ClipboardItem) {
        var normalized = item.withPersistedImage()
        if let duplicateIndex = items.firstIndex(where: { isDuplicate($0, normalized) }) {
            let existing = items.remove(at: duplicateIndex)
            normalized.isPinned = existing.isPinned || normalized.isPinned
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
        save()
    }

    func clearHistory() {
        let toDelete = items.filter { !$0.isPinned }
        for item in toDelete {
            if let imagePath = item.imagePath {
                ImageAssetStore.shared.deleteImage(relativePath: imagePath)
            }
        }
        items.removeAll { !$0.isPinned }
        save()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let willPin = !items[index].isPinned
        items[index].isPinned = willPin

        if willPin {
            // Keep existing pinned cards stable: append after them instead of jumping to front.
            let otherPinnedCount = items.filter { $0.isPinned && $0.id != item.id }.count
            let moved = items.remove(at: index)
            if otherPinnedCount == 0 {
                items.insert(moved, at: 0)
            } else if let lastPinnedIndex = items.lastIndex(where: \.isPinned) {
                items.insert(moved, at: lastPinnedIndex + 1)
            } else {
                items.insert(moved, at: 0)
            }
            selectedItemID = moved.id
        }
        save()
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

    private func orderedHistoryItems(_ source: [ClipboardItem]) -> [ClipboardItem] {
        let pinned = source.filter(\.isPinned)
        let rest = source.filter { !$0.isPinned }
        return pinned + rest
    }

    private func trimHistory() {
        guard historyLimit > 0 else { return }
        let unpinnedCount = items.filter { !$0.isPinned }.count
        guard unpinnedCount > historyLimit else { return }
        var removed = 0
        let target = unpinnedCount - historyLimit
        items = items.filter { item in
            if item.isPinned { return true }
            if removed < target {
                removed += 1
                if let imagePath = item.imagePath {
                    ImageAssetStore.shared.deleteImage(relativePath: imagePath)
                }
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

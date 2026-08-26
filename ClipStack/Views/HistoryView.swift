import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var hoveredItemID: UUID?
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(spacing: 8) {
                topBar
                    .padding(.horizontal, AppTheme.stripPadding)
                    .padding(.top, 14)

                categoryFilterBar
                    .padding(.horizontal, AppTheme.stripPadding)

                content
                    .padding(.horizontal, AppTheme.stripPadding)
                    .padding(.bottom, 16)
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.dockBackground)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 28, y: -4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) {
            guard !searchFocused else { return .ignored }
            appState.moveSelection(offset: -1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !searchFocused else { return .ignored }
            appState.moveSelection(offset: 1)
            return .handled
        }
        .onKeyPress(.return) {
            guard !searchFocused else { return .ignored }
            appState.insertSelectedItem()
            return .handled
        }
        .onKeyPress(.delete) {
            guard !searchFocused else { return .ignored }
            appState.deleteSelectedItem()
            return .handled
        }
        .onKeyPress(.deleteForward) {
            guard !searchFocused else { return .ignored }
            appState.deleteSelectedItem()
            return .handled
        }
        .onKeyPress(.escape) {
            appState.onClosePanel?()
            return .handled
        }
        .onChange(of: appState.selectedTab) { _, _ in
            appState.selectFirstItemIfNeeded()
        }
        .onChange(of: appState.searchQuery) { _, _ in
            appState.selectFirstItemIfNeeded()
        }
        .onChange(of: appState.selectedContentFilter) { _, _ in
            appState.selectFirstItemIfNeeded()
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            if !appState.isSearching {
                tabButtons
            } else {
                searchModeBadge
            }

            searchField

            Spacer()

            if !appState.isSearching {
                trailingActions
            }
        }
    }

    private var searchModeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
            Text("全库搜索")
                .font(.system(size: 12, weight: .semibold))
            Text("(\(appState.searchResultCount))")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12), in: Capsule())
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)
            TextField("搜索历史、固定板、图片文字…", text: Bindable(appState).searchQuery)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .foregroundStyle(.white)
                .onTapGesture {
                    focusSearchField()
                }
                .onSubmit {
                    focusSearchField()
                }

            if appState.isSearching {
                Button {
                    appState.clearSearch()
                    focusSearchField()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.1))
        }
        .frame(maxWidth: 360)
        .onAppear {
            syncSearchFocus()
        }
        .onChange(of: appState.shouldFocusSearch) { _, shouldFocus in
            if shouldFocus {
                syncSearchFocus()
            }
        }
    }

    private func focusSearchField() {
        NSApp.activate(ignoringOtherApps: true)
        appState.shouldFocusSearch = true
    }

    private func syncSearchFocus() {
        appState.shouldFocusSearch = false
        DispatchQueue.main.async {
            searchFocused = true
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ContentTypeFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            appState.selectedContentFilter = filter
                        }
                    } label: {
                        Label(filter.rawValue, systemImage: filter.icon)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(
                                appState.selectedContentFilter == filter ? Color.white : AppTheme.mutedText
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                Capsule().fill(
                                    appState.selectedContentFilter == filter
                                        ? AppTheme.accent.opacity(0.55)
                                        : Color.white.opacity(0.08)
                                )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 28)
    }

    private var tabButtons: some View {
        HStack(spacing: 6) {
            ForEach(HistoryTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        appState.selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(appState.selectedTab == tab ? Color.white : AppTheme.mutedText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            if appState.selectedTab == tab {
                                Capsule().fill(Color.white.opacity(0.16))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var trailingActions: some View {
        switch appState.selectedTab {
        case .stack:
            actionChip("依次插入", systemImage: "arrow.right.doc.on.clipboard") {
                Task { await appState.insertStackSequentially() }
            }
            actionChip("清空", systemImage: "trash") {
                appState.clearStack()
            }
        case .history:
            actionChip("清空历史", systemImage: "trash") {
                appState.clearHistory()
            }
        case .pinboards:
            actionChip("新建", systemImage: "plus") {
                appState.addPinboard(named: "固定板 \(appState.pinboards.count + 1)")
            }
        }
    }

    private func actionChip(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        if appState.isSearching {
            ItemStripView(
                items: appState.filteredHistoryItems,
                emptyMessage: emptyMessageForCurrentView,
                hoveredItemID: $hoveredItemID,
                highlightQuery: appState.parsedSearchQuery.raw
            )
        } else {
            switch appState.selectedTab {
            case .history:
                ItemStripView(
                    items: appState.filteredHistoryItems,
                    emptyMessage: emptyMessageForCurrentView,
                    hoveredItemID: $hoveredItemID,
                    highlightQuery: nil
                )
            case .pinboards:
                VStack(alignment: .leading, spacing: 8) {
                    pinboardPicker
                    ItemStripView(
                        items: appState.pinnedItems,
                        emptyMessage: emptyMessageForCurrentView,
                        hoveredItemID: $hoveredItemID,
                        highlightQuery: nil
                    )
                }
            case .stack:
                ItemStripView(
                    items: appState.stackItems,
                    emptyMessage: emptyMessageForCurrentView,
                    hoveredItemID: $hoveredItemID,
                    highlightQuery: nil
                )
            }
        }
    }

    private var emptyMessageForCurrentView: String {
        if appState.isSearching && appState.isFilteringByType {
            return "没有匹配「\(appState.parsedSearchQuery.raw)」的\(appState.selectedContentFilter.rawValue)内容"
        }
        if appState.isSearching {
            return "没有匹配「\(appState.parsedSearchQuery.raw)」的内容"
        }
        if appState.isFilteringByType {
            return "当前分类下暂无\(appState.selectedContentFilter.rawValue)内容"
        }
        switch appState.selectedTab {
        case .history:
            return "复制一些内容，它们会出现在这里"
        case .pinboards:
            return "右键条目可固定到这里"
        case .stack:
            return "把条目加入队列后可依次插入"
        }
    }

    private var pinboardPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.pinboards) { board in
                    Button {
                        appState.selectedPinboardID = board.id
                        appState.selectFirstItemIfNeeded()
                    } label: {
                        Text(board.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(appState.selectedPinboardID == board.id ? .white : AppTheme.mutedText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                Capsule().fill(
                                    appState.selectedPinboardID == board.id
                                        ? AppTheme.accent.opacity(0.55)
                                        : Color.white.opacity(0.08)
                                )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 28)
    }
}

struct ItemStripView: View {
    @Environment(AppState.self) private var appState
    let items: [ClipboardItem]
    let emptyMessage: String
    @Binding var hoveredItemID: UUID?
    let highlightQuery: String?

    var body: some View {
        if items.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: appState.isSearching ? "magnifyingglass" : "doc.on.clipboard")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(AppTheme.mutedText)
                    Text(emptyMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.mutedText)
                        .multilineTextAlignment(.center)
                    if appState.isSearching {
                        Text("支持 type:image · app:Safari · 固定:默认")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.mutedText.opacity(0.8))
                    }
                }
                .frame(height: AppTheme.cardStripHeight)
                Spacer()
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppTheme.cardSpacing) {
                        ForEach(items) { item in
                            ItemCardView(
                                item: item,
                                isHovered: hoveredItemID == item.id,
                                isSelected: appState.selectedItemID == item.id,
                                highlightQuery: highlightQuery
                            )
                            .id(item.id)
                            .onHover { hovering in
                                hoveredItemID = hovering ? item.id : nil
                                if hovering { appState.selectedItemID = item.id }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.cardHoverOverflow / 2)
                    .padding(.vertical, AppTheme.cardHoverOverflow)
                }
                .scrollClipDisabled(true)
                .frame(height: AppTheme.cardStripHeight)
                .onChange(of: appState.selectedItemID) { _, newID in
                    guard let newID else { return }
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
                .onAppear {
                    appState.selectFirstItemIfNeeded()
                }
            }
        }
    }
}

struct ItemCardView: View {
    @Environment(AppState.self) private var appState
    let item: ClipboardItem
    let isHovered: Bool
    let isSelected: Bool
    let highlightQuery: String?

    private var isActive: Bool { isHovered || isSelected }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader

            previewArea
                .frame(width: AppTheme.cardWidth - 20, height: AppTheme.cardPreviewHeight)
                .padding(.horizontal, 10)

            actionBar
                .frame(height: AppTheme.cardActionHeight)
                .opacity(isActive ? 1 : 0)
                .allowsHitTesting(isActive)
        }
        .frame(width: AppTheme.cardWidth, height: AppTheme.cardHeight)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                .strokeBorder(isActive ? AppTheme.accent.opacity(0.65) : AppTheme.cardBorder, lineWidth: isActive ? 1.5 : 0.8)
        }
        .shadow(color: AppTheme.cardShadow, radius: isActive ? 14 : 8, y: isActive ? 4 : 3)
        .scaleEffect(isActive ? AppTheme.cardHoverScale : 1.0, anchor: .bottom)
        .offset(y: isActive ? -AppTheme.cardHoverLift : 0)
        .zIndex(isActive ? 10 : 0)
        .animation(.easeOut(duration: 0.15), value: isActive)
        .onTapGesture(count: 2) {
            appState.onInsertItem?(item)
        }
        .contextMenu {
            cardContextMenu
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 6) {
            appIcon
            VStack(alignment: .leading, spacing: 1) {
                Text(item.sourceAppName ?? "未知")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let pinboardName = appState.pinboardName(for: item.pinboardID) {
                    Text("固定: \(pinboardName)")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.accent.opacity(0.85))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: AppTheme.cardHeaderHeight, alignment: .center)
    }

    private var actionBar: some View {
        ZStack {
            cardAction("插入", prominent: true) {
                appState.onInsertItem?(item)
            }
            .frame(width: 76)

            HStack {
                Spacer()
                cardMenu
            }
            .padding(.trailing, 8)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let bundleID = item.sourceBundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            Image(nsImage: icon)
                .resizable()
                .frame(width: 14, height: 14)
        } else {
            Image(systemName: item.typeIcon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 14, height: 14)
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        Group {
            if let image = item.thumbnailImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.04))
            } else if item.isCodeSnippet, let text = item.text {
                CodePreviewView(text: text, language: item.codeLanguage)
            } else {
                highlightedText(item.displayTextForSearch)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.24))
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(item.isCodeSnippet ? Color.clear : Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardInnerCorner, style: .continuous))
        .clipped()
    }

    private var cardMenu: some View {
        Menu {
            cardContextMenu
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 22)
                .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private var cardContextMenu: some View {
        Button("插入") { appState.onInsertItem?(item) }
        if item.pinboardID == nil {
            ForEach(appState.pinboards) { board in
                Button("固定到 \(board.name)") { appState.pinItem(item, to: board.id) }
            }
        } else {
            Button("取消固定") { appState.unpinItem(item) }
        }
        Button("加入插入队列") { appState.addToStack(item) }
        if appState.stackItemIDs.contains(item.id) {
            Button("移出队列") { appState.removeFromStack(item) }
        }
        Divider()
        Button("纯文本插入") { ClipboardInsertService.insert(item, asPlainText: true) }
        Button("删除", role: .destructive) { appState.deleteItem(item) }
    }

    private func cardAction(_ title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(prominent ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    prominent ? AppTheme.accent : Color.black.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
    }
    @ViewBuilder
    private func highlightedText(_ text: String) -> some View {
        if let highlightQuery,
           !highlightQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let token = ClipboardSearch.parse(highlightQuery).tokens.first,
           !token.isEmpty {
            let lowerText = text.lowercased()
            let lowerToken = token.lowercased()
            if let range = lowerText.range(of: lowerToken) {
                let start = String(text[..<range.lowerBound])
                let match = String(text[range])
                let end = String(text[range.upperBound...])
                (Text(start) + Text(match).foregroundStyle(AppTheme.accent).bold() + Text(end))
            } else {
                Text(text)
            }
        } else {
            Text(text)
        }
    }
}

struct CodePreviewView: View {
    let text: String
    let language: CodeLanguage

    var body: some View {
        ScrollView {
            Text(CodeHighlighter.highlight(text: text, language: language))
                .font(.system(size: 10, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(6)
        }
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardInnerCorner, style: .continuous))
    }
}

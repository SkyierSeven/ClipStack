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
            .overlay(alignment: .top) {
                if appState.copyToastToken != nil {
                    copiedToast
                        .padding(.top, 18)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: appState.copyToastToken)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .focusable()
        .focusEffectDisabled(true)
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
            appState.copySelectedItem()
            return .handled
        }
        .onKeyPress(.space) {
            guard !searchFocused else { return .ignored }
            appState.previewSelectedItem()
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

    private var copiedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            Text("已复制到剪贴板")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            Capsule(style: .continuous)
                .fill(Color(red: 0.18, green: 0.72, blue: 0.42))
                .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        )
        .accessibilityLabel("已复制到剪贴板")
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
            TextField("搜索历史、图片文字…", text: Bindable(appState).searchQuery)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .focusEffectDisabled(true)
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
                highlightQuery: appState.parsedSearchQuery.raw,
                showsGuideCard: false
            )
        } else {
            switch appState.selectedTab {
            case .history:
                ItemStripView(
                    items: appState.filteredHistoryItems,
                    emptyMessage: emptyMessageForCurrentView,
                    hoveredItemID: $hoveredItemID,
                    highlightQuery: nil,
                    showsGuideCard: true
                )
            case .stack:
                ItemStripView(
                    items: appState.stackItems,
                    emptyMessage: emptyMessageForCurrentView,
                    hoveredItemID: $hoveredItemID,
                    highlightQuery: nil,
                    showsGuideCard: false
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
        case .stack:
            return "把条目加入队列后可依次插入"
        }
    }
}

struct ItemStripView: View {
    @Environment(AppState.self) private var appState
    let items: [ClipboardItem]
    let emptyMessage: String
    @Binding var hoveredItemID: UUID?
    let highlightQuery: String?
    var showsGuideCard: Bool = false

    private static let guideCardID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    var body: some View {
        if items.isEmpty && !showsGuideCard {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppTheme.cardSpacing) {
                        if showsGuideCard {
                            GuideCardView()
                                .id(Self.guideCardID)
                        }

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

                        if items.isEmpty {
                            emptyStateInline
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

    private var emptyState: some View {
        HStack {
            Spacer()
            emptyStateContent
                .frame(height: AppTheme.cardStripHeight)
            Spacer()
        }
    }

    private var emptyStateInline: some View {
        emptyStateContent
            .frame(width: AppTheme.cardWidth, height: AppTheme.cardHeight)
            .padding(.leading, 4)
    }

    private var emptyStateContent: some View {
        VStack(spacing: 8) {
            Image(systemName: appState.isSearching ? "magnifyingglass" : "doc.on.clipboard")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AppTheme.mutedText)
            Text(emptyMessage)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
            if appState.isSearching {
                Text("支持 type:image · app:Safari · pin:")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.mutedText.opacity(0.8))
            }
        }
    }
}

/// Fixed leading card that teaches basic interactions. Not a clipboard item.
struct GuideCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: CardColors { AppTheme.colors(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                Text("操作提示")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(colors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 12) {
                guideRow(icon: "hand.tap.fill", title: "点击卡片", detail: "复制")
                guideRow(icon: "eye.fill", title: "滑入后空格", detail: "预览")
                guideRow(icon: "arrow.left.arrow.right", title: "左右方向键", detail: "切换")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
        .frame(width: AppTheme.cardWidth, height: AppTheme.cardHeight)
        .background(colors.background, in: RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                .strokeBorder(AppTheme.accent.opacity(colorScheme == .dark ? 0.45 : 0.35), lineWidth: 1)
        }
        .shadow(color: colors.shadow, radius: 8, y: 3)
    }

    private func guideRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(colors.primaryText)

            Spacer(minLength: 4)

            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(colors.secondaryText)
        }
        .frame(maxWidth: 140)
    }
}

struct ItemCardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    let item: ClipboardItem
    let isHovered: Bool
    let isSelected: Bool
    let highlightQuery: String?

    /// Keyboard/default selection highlight — does not enlarge the card.
    private var showsSelectionChrome: Bool { isSelected || isHovered }

    /// Pinned cards stay still — no hover lift/scale.
    private var showsHoverMotion: Bool { isHovered && !item.isPinned }

    private var colors: CardColors { AppTheme.colors(for: colorScheme) }

    private var borderColor: Color {
        if item.isPinned { return colors.pinnedBorder }
        return showsSelectionChrome ? colors.selectedBorder : colors.border
    }

    private var borderWidth: CGFloat {
        if item.isPinned { return 1.5 }
        return showsSelectionChrome ? 1.2 : 0.8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader

            previewArea
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: AppTheme.cardWidth, height: AppTheme.cardHeight)
        .background(colors.background, in: RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
        .focusEffectDisabled(true)
        .shadow(color: colors.shadow, radius: showsHoverMotion ? 14 : 8, y: showsHoverMotion ? 4 : 3)
        .scaleEffect(showsHoverMotion ? AppTheme.cardHoverScale : 1.0, anchor: .bottom)
        .offset(y: showsHoverMotion ? -AppTheme.cardHoverLift : 0)
        .zIndex(showsHoverMotion ? 10 : (isSelected || item.isPinned ? 1 : 0))
        .animation(.easeOut(duration: 0.15), value: showsHoverMotion)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: item.isPinned)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCorner, style: .continuous))
        .onTapGesture {
            appState.copyItem(item)
        }
        .contextMenu {
            cardContextMenu
        }
    }

    private var cardHeader: some View {
        HStack(spacing: 6) {
            appIcon
            Text(item.sourceAppName ?? "未知")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colors.secondaryText)
                .lineLimit(1)

            Spacer(minLength: 0)

            Button {
                appState.togglePin(item)
            } label: {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(item.isPinned ? AppTheme.pinAccent : colors.secondaryText.opacity(0.7))
                    .frame(width: 22, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(item.isPinned || isHovered ? 1 : 0)
            .help(item.isPinned ? "取消固定" : "固定到列表前面")
        }
        .padding(.horizontal, 10)
        .frame(height: AppTheme.cardHeaderHeight, alignment: .center)
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
                .foregroundStyle(colors.secondaryText)
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
                    .background(colors.previewFill)
            } else if item.isCodeSnippet, let text = item.text {
                CodePreviewView(text: text, language: item.codeLanguage)
            } else {
                highlightedText(item.displayTextForSearch)
                    .font(.system(size: 11))
                    .foregroundStyle(colors.previewText)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(item.isCodeSnippet ? Color.clear : colors.previewFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardInnerCorner, style: .continuous))
        .clipped()
    }

    @ViewBuilder
    private var cardContextMenu: some View {
        Button("复制到剪贴板") { appState.copyItem(item) }
        Button("插入到当前应用") { appState.insertItem(item) }
        Button("快速查看") { appState.previewItem(item) }
        Button(item.isPinned ? "取消固定" : "固定") { appState.togglePin(item) }
        Button("加入插入队列") { appState.addToStack(item) }
        if appState.stackItemIDs.contains(item.id) {
            Button("移出队列") { appState.removeFromStack(item) }
        }
        Divider()
        Button("纯文本插入") { appState.insertItem(item, asPlainText: true) }
        Button("删除", role: .destructive) { appState.deleteItem(item) }
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

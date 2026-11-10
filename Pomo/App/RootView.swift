// Pomo/App/RootView.swift

import SwiftUI

/// Picks the layout for the device shape (iPhone, iPhone Duo outer/inner, half folded) and
/// hosts the three sections with Pomo's own tab bar.
struct RootView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @EnvironmentObject private var timerViewModel: TimerViewModel
    @State private var fold: PomoFold?

    var body: some View {
        #if DEBUG
        if let preview = UserDefaults.standard.string(forKey: "PomoPreviewLayout") {
            DebugLayoutPreview(kind: preview, selectedTab: $selectedTab)
        } else {
            content
        }
        #else
        content
        #endif
    }

    private var content: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 600
            Group {
                if let fold, fold.axis == .horizontal, selectedTab == PomoTab.timer.rawValue {
                    // Rotated or half folded like a laptop: look at the top, touch the bottom
                    TimerView(layout: .folded(top: fold.before, gap: fold.gap), selectedTab: $selectedTab)
                } else if let fold, fold.axis == .vertical {
                    wideContent(split: fold)
                } else if isWide {
                    wideContent(split: nil)
                } else {
                    compactContent
                }
            }
            .animation(.smooth, value: fold)
        }
        .onPomoFoldChange { fold = $0 }
        .tint(timerViewModel.currentType.tint)
    }

    private var tabTint: Color {
        selectedTab == PomoTab.timer.rawValue ? timerViewModel.currentType.tint : PomoPalette.focus
    }

    private var compactContent: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            // iPhone Duo's outer screen has its sensor bar (and Dynamic Island) on a side edge:
            // the section switcher moves into that strip so the timer keeps the full height.
            let sideStrip = max(insets.leading, insets.trailing)
            if sideStrip >= 44 {
                let onTrailing = insets.trailing >= insets.leading
                section(layout: .compact)
                    .overlay(alignment: onTrailing ? .bottomTrailing : .bottomLeading) {
                        PomoSideToolbar(selection: $selectedTab, tint: tabTint)
                            .frame(width: sideStrip)
                            .padding(.bottom, PomoSpace.m)
                            .offset(x: onTrailing ? sideStrip : -sideStrip)
                    }
            } else {
                section(layout: .compact)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        PomoTabBar(selection: $selectedTab, tint: tabTint)
                            .padding(.horizontal, PomoSpace.l)
                            .padding(.bottom, PomoSpace.xxs)
                    }
            }
        }
    }

    @ViewBuilder
    private func wideContent(split: PomoFold?) -> some View {
        if selectedTab == PomoTab.timer.rawValue {
            TimerView(layout: .wide(split: split), selectedTab: $selectedTab)
        } else {
            section(layout: .wide(split: split))
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        PomoTabBar(selection: $selectedTab, tint: tabTint, showsAllTitles: true)
                            .fixedSize()
                    }
                    .padding(.horizontal, PomoSpace.l + 6)
                    .padding(.vertical, PomoSpace.xs)
                    .background(PomoPalette.background)
                }
        }
    }

    @ViewBuilder
    private func section(layout: TimerLayout) -> some View {
        switch PomoTab(rawValue: selectedTab) ?? .timer {
        case .timer: TimerView(layout: layout, selectedTab: $selectedTab)
        case .statistics: StatisticsView()
        case .settings: SettingsView()
        }
    }
}

#if DEBUG
/// DEBUG only (`-PomoPreviewLayout wide|folded`): renders an iPhone Duo inner-screen layout at
/// its real size, scaled to fit, so it can be reviewed on any simulator.
private struct DebugLayoutPreview: View {
    let kind: String
    @Binding var selectedTab: Int

    var body: some View {
        // Inner screen measured on iPhone Duo: 951 x 669 pt open like a book, hinge 40 pt wide at x = 455.5
        let folded = kind == "folded"
        let size = folded ? CGSize(width: 669, height: 951) : CGSize(width: 951, height: 669)
        let hinge = PomoFold(axis: folded ? .horizontal : .vertical, before: 456, gap: 40)
        GeometryReader { proxy in
            let scale = min(proxy.size.width / size.width, proxy.size.height / size.height)
            TimerView(layout: folded ? .folded(top: hinge.before, gap: hinge.gap) : .wide(split: hinge),
                      selectedTab: $selectedTab)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.gray.opacity(0.3))
        .ignoresSafeArea()
    }
}
#endif

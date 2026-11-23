// Pomo/DesignSystem/PomoComponents.swift
//
// iPhone components of the "Cocina" design system (tokens, the dial and the mark live in
// Shared/DesignSystem/PomoDesign.swift).

import SwiftUI

// MARK: - Page

/// Warm cream page used by Statistics, Settings and the Duo's side panels.
struct PomoPage: View {
    var body: some View {
        PomoPalette.background.ignoresSafeArea().accessibilityHidden(true)
    }
}

// MARK: - Card

struct PomoCardModifier: ViewModifier {
    var padding: CGFloat = PomoSpace.m

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PomoPalette.surface, in: RoundedRectangle(cornerRadius: PomoRadius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PomoRadius.l, style: .continuous)
                    .strokeBorder(PomoPalette.hairline, lineWidth: 1)
            )
    }
}

extension View {
    /// White card with a warm outline.
    func pomoCard(padding: CGFloat = PomoSpace.m) -> some View {
        modifier(PomoCardModifier(padding: padding))
    }
}

// MARK: - Buttons

/// Round control button: the ink primary (play/pause) or a white secondary.
struct PomoRoundButton: View {
    enum Role { case primary, secondary }

    let systemImage: String
    let label: String
    var role: Role = .secondary
    var diameter: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: diameter * (role == .primary ? 0.34 : 0.34), weight: .bold))
                .foregroundStyle(role == .primary ? PomoPalette.cream : PomoPalette.ink)
                .frame(width: diameter, height: diameter)
                .background {
                    if role == .primary {
                        Circle().fill(PomoPalette.ink)
                            .shadow(color: PomoPalette.ink.opacity(0.25), radius: 10, y: 8)
                    } else {
                        Circle().fill(Color.white)
                            .overlay(Circle().strokeBorder(PomoPalette.buttonOutline, lineWidth: 2))
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(PomoPressStyle())
        .accessibilityLabel(label)
    }
}

/// Subtle press feedback for custom buttons.
struct PomoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Capsule label on a colored field.
struct PomoFieldPill: View {
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).font(.subheadline.weight(.bold))
            }
            Text(text).font(.pomoRounded(.callout))
        }
        .foregroundStyle(PomoPalette.cream)
        .padding(.horizontal, PomoSpace.m)
        .frame(minHeight: 36)
        .background(PomoPalette.ink.opacity(0.22), in: Capsule())
    }
}

// MARK: - Tab bar

enum PomoTab: Int, CaseIterable, Identifiable {
    case timer, statistics, settings
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .timer: return String(localized: "Timer")
        case .statistics: return String(localized: "Estadísticas")
        case .settings: return String(localized: "Ajustes")
        }
    }

    var systemImage: String {
        switch self {
        case .timer: return "timer"
        case .statistics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Bottom bar: the selected tab is a capsule in the current session color, the others are icons.
struct PomoTabBar: View {
    @Binding var selection: Int
    var tint: Color
    /// Shows every title (Duo inner screen header) instead of icons only.
    var showsAllTitles = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PomoTab.allCases) { tab in
                let isSelected = selection == tab.rawValue
                Button {
                    withAnimation(.snappy) { selection = tab.rawValue }
                } label: {
                    HStack(spacing: 6) {
                        if !showsAllTitles || isSelected {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 17, weight: .bold))
                        }
                        if isSelected || showsAllTitles {
                            Text(tab.title)
                                .font(.pomoRounded(.footnote))
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(isSelected ? PomoPalette.cream : PomoPalette.inkText)
                    .padding(.horizontal, PomoSpace.m)
                    .frame(maxWidth: isSelected && !showsAllTitles ? .infinity : nil, minHeight: 48)
                    .frame(minWidth: 64)
                    .background {
                        if isSelected {
                            Capsule().fill(tint)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(PomoPressStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(5)
        .background(PomoPalette.chrome, in: Capsule())
        .accessibilityElement(children: .contain)
    }
}

/// Vertical section switcher that lives in a side safe area (iPhone Duo's sensor bar strip),
/// so the main view keeps its full height.
struct PomoSideToolbar: View {
    @Binding var selection: Int
    var tint: Color

    var body: some View {
        VStack(spacing: 6) {
            ForEach(PomoTab.allCases) { tab in
                let isSelected = selection == tab.rawValue
                Button {
                    withAnimation(.snappy) { selection = tab.rawValue }
                } label: {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? PomoPalette.cream : PomoPalette.ink)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(isSelected ? tint : Color.clear))
                        .contentShape(Circle())
                }
                .buttonStyle(PomoPressStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(5)
        .background(PomoPalette.chrome, in: Capsule())
        .shadow(color: PomoPalette.ink.opacity(0.12), radius: 8, y: 4)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Section header

struct PomoSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.pomoRounded(.title3, weight: .black))
                .foregroundStyle(PomoPalette.inkText)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PomoPalette.muted)
            }
        }
    }
}

// MARK: - Stat tile

struct PomoStatTile: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.pomoRounded(.largeTitle, weight: .black))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PomoPalette.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pomoCard()
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

// MARK: - Setting rows

/// Labelled value with a slider, e.g. a session length.
struct PomoSliderRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    @Binding var value: Int
    let range: ClosedRange<Int>
    var unit: String? = String(localized: "min", comment: "Minutes abbreviation")

    var body: some View {
        VStack(alignment: .leading, spacing: PomoSpace.xs) {
            HStack(spacing: PomoSpace.s) {
                PomoIconBadge(systemImage: systemImage, tint: tint)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PomoPalette.inkText)
                Spacer()
                Text(valueText)
                    .font(.pomoRounded(.body, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }
            Slider(value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
                   in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .tint(tint)
                .accessibilityLabel(title)
                .accessibilityValue(valueText)
        }
    }

    private var valueText: String {
        if let unit { return "\(value) \(unit)" }
        return "\(value)"
    }
}

/// Toggle with an icon badge and an optional explanation.
struct PomoToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: PomoSpace.s) {
                PomoIconBadge(systemImage: systemImage, tint: tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PomoPalette.inkText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(PomoPalette.muted)
                    }
                }
            }
        }
        .tint(tint)
    }
}

/// Rounded square holding an SF Symbol in the accent color.
struct PomoIconBadge: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Thin separator between rows inside a card.
struct PomoDivider: View {
    var body: some View {
        Rectangle()
            .fill(PomoPalette.hairline)
            .frame(height: 1)
            .padding(.vertical, PomoSpace.xs)
    }
}

// MARK: - Hinge (iPhone Duo)

/// Where iPhone Duo's hinge crosses the view, as reported by the system
/// (`reservedRegions(kind: .division)`, iOS 27.1). Not inferred from the model or the size:
/// the same device has a vertical hinge held open like a book, a horizontal one when rotated
/// or half folded like a laptop. The region is reported inactive while the Duo lies flat, but
/// content across it still reads broken, so inactive regions count too.
struct PomoFold: Equatable {
    enum Axis: Equatable {
        /// Runs top to bottom: split left | right.
        case vertical
        /// Runs left to right: split top / bottom (laptop posture).
        case horizontal
    }

    var axis: Axis
    /// Width (vertical) or height (horizontal) of the part before the hinge.
    var before: CGFloat
    /// Space the hinge takes, margins included.
    var gap: CGFloat

    static func measure(in proxy: GeometryProxy) -> PomoFold? {
        guard #available(iOS 27.1, *) else { return nil }
        let size = proxy.size
        for region in proxy.reservedRegions(kind: .division, options: .includeInactive) {
            let frame = region.frame
            if frame.height > frame.width, frame.minX > 0, frame.maxX < size.width {
                return PomoFold(axis: .vertical, before: frame.minX.rounded(), gap: frame.width.rounded())
            }
            if frame.width > frame.height, frame.minY > 0, frame.maxY < size.height {
                return PomoFold(axis: .horizontal, before: frame.minY.rounded(), gap: frame.height.rounded())
            }
        }
        return nil
    }
}

extension EnvironmentValues {
    /// iPhone Duo's hinge across the current screen, if any (set by the root view).
    @Entry var pomoFold: PomoFold? = nil
    /// Height of the floating tab bar over the bottom of the screen (0 when there is none).
    @Entry var pomoBottomBarHeight: CGFloat = 0
}

extension View {
    /// Keeps content clear of the floating tab bar. Apply it inside navigation stacks, right on
    /// the scrolling content: a bottom inset added outside a NavigationStack does not reach
    /// its scroll views, so the last rows ended up under the bar.
    func pomoBottomBarSpace() -> some View {
        modifier(PomoBottomBarSpace())
    }
}

private struct PomoBottomBarSpace: ViewModifier {
    @Environment(\.pomoBottomBarHeight) private var height

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: height)
        }
    }
}

/// Two scrolling panes split exactly at a vertical hinge, or one scrolling column otherwise.
struct PomoFoldPanes<Leading: View, Trailing: View>: View {
    @Environment(\.pomoFold) private var fold
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        panes.pomoBottomBarSpace()
    }

    @ViewBuilder
    private var panes: some View {
        if let fold, fold.axis == .vertical {
            HStack(spacing: 0) {
                pane(leading).frame(width: fold.before)
                Rectangle().fill(PomoPalette.hairline).frame(width: 2).frame(width: fold.gap)
                    .accessibilityHidden(true)
                pane(trailing).frame(maxWidth: .infinity)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: PomoSpace.l) {
                    leading()
                    trailing()
                }
                .padding(.horizontal, PomoSpace.m)
                .padding(.bottom, PomoSpace.xl)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func pane<Content: View>(_ content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PomoSpace.l) {
                content()
            }
            .padding(.horizontal, PomoSpace.l)
            .padding(.vertical, PomoSpace.m)
        }
    }
}

extension View {
    /// Measures iPhone Duo's hinge on every geometry change (open, fold, rotate). Always nil
    /// on other devices. Measure on a full-size container, never on a stack whose size depends
    /// on the result (that would loop the layout).
    func onPomoFoldChange(_ action: @escaping (PomoFold?) -> Void) -> some View {
        onGeometryChange(for: PomoFold?.self) { proxy in
            PomoFold.measure(in: proxy)
        } action: { fold in
            action(fold)
        }
    }
}

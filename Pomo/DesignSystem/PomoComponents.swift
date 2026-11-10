// Pomo/DesignSystem/PomoComponents.swift
//
// iPhone components of the Pomo design system (tokens and the mark live in
// Shared/DesignSystem/PomoDesign.swift).

import SwiftUI

// MARK: - Screen background

/// Warm neutral page with a soft wash of the current accent at the top.
struct PomoScreenBackground: View {
    var tint: Color = PomoPalette.focus
    var intensity: Double = 0.16

    var body: some View {
        ZStack {
            PomoPalette.background
            RadialGradient(colors: [tint.opacity(intensity), .clear],
                           center: .top, startRadius: 0, endRadius: 520)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
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
    /// Groups content on an elevated surface.
    func pomoCard(padding: CGFloat = PomoSpace.m) -> some View {
        modifier(PomoCardModifier(padding: padding))
    }

    /// Liquid Glass on iOS 26, a material before.
    @ViewBuilder
    func pomoGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// The single prominent action of a screen.
    @ViewBuilder
    func pomoPrimaryButton(tint: Color) -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glassProminent).tint(tint)
        } else {
            self.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).tint(tint)
        }
    }

    /// Secondary actions next to the primary one.
    @ViewBuilder
    func pomoSecondaryButton() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass).tint(.primary)
        } else {
            self.buttonStyle(.bordered).buttonBorderShape(.capsule).tint(.primary)
        }
    }
}

// MARK: - Section header

struct PomoSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.pomoRounded(.title3, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Stat tile

struct PomoStatTile<Icon: View>: View {
    let value: String
    let label: String
    let tint: Color
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        VStack(alignment: .leading, spacing: PomoSpace.xs) {
            icon()
                .frame(width: 28, height: 28)
                .foregroundStyle(tint)
            Text(value)
                .font(.pomoRounded(.title, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .pomoCard()
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
                    .font(.body)
                Spacer()
                Text(valueText)
                    .font(.pomoRounded(.body))
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
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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

// Shared/DesignSystem/PomoDesign.swift
//
// Pomo design system: tokens and the Pomo mark, shared by the iPhone app, the Watch
// app, the widgets and the Live Activity.
//
// Principles
// - Calm and minimal: one accent at a time (the current session's color), generous space.
// - Numbers are the hero: rounded, monospaced digits for every time value.
// - No emoji: icons are SF Symbols or the vector Pomo mark below.
// - Accessible by default: semantic text styles (Dynamic Type), 44 pt targets, VoiceOver
//   labels, Reduce Motion respected.

import SwiftUI

// MARK: - Tokens

enum PomoSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum PomoRadius {
    static let s: CGFloat = 12
    static let m: CGFloat = 18
    static let l: CGFloat = 26
}

enum PomoPalette {
    /// Focus sessions: tomato.
    static let focus = Color("PomoPrimary")
    /// Short breaks: teal.
    static let shortBreak = Color("PomoSecondary")
    /// Long breaks: calm indigo.
    static let longBreak = Color("PomoLongBreak")
    /// Warm neutral page background.
    static let background = Color("PomoBackground")
    /// Cards and grouped content.
    static let surface = Color("PomoSurface")
    /// Thin separators and card outlines.
    static let hairline = Color("PomoHairline")
    /// Leaves of the Pomo mark.
    static let leaf = Color("PomoSecondary")
}

extension TimerType {
    /// The single accent used while this session type is shown.
    var tint: Color {
        switch self {
        case .work: return PomoPalette.focus
        case .shortBreak: return PomoPalette.shortBreak
        case .longBreak: return PomoPalette.longBreak
        }
    }

    /// SF Symbol for the session type.
    var symbolName: String {
        switch self {
        case .work: return "target"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }
}

extension Font {
    /// Rounded, monospaced digits for time values.
    static func pomoNumber(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Rounded text style that follows Dynamic Type.
    static func pomoRounded(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

// MARK: - Pomo mark

/// The Pomo mark: a kitchen tomato timer (body, leaves, dial and pointer), drawn as vectors
/// so it stays crisp at every size and can take any tint.
struct PomoMark: View {
    var tint: Color = PomoPalette.focus
    var leafTint: Color = PomoPalette.leaf
    /// Draws the dial and pointer (hide them at very small sizes).
    var showsDial: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                PomoMarkBody().fill(tint)
                if showsDial {
                    PomoMarkDial().stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: max(1, side * 0.026), lineCap: .round))
                    PomoMarkPointer().fill(.white.opacity(0.75))
                }
                PomoMarkLeaves().fill(leafTint)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private extension CGRect {
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: minX + x * width, y: minY + y * height)
    }
}

/// Slightly wide, rounded tomato body.
struct PomoMarkBody: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.07, y: rect.minY + rect.height * 0.22,
                               width: rect.width * 0.86, height: rect.height * 0.74))
    }
}

/// Crown of pointed leaves on top of the body.
struct PomoMarkLeaves: Shape {
    func path(in rect: CGRect) -> Path {
        let center = rect.point(0.5, 0.25)
        // (angle in degrees, radius as a fraction of the width): tips alternate with valleys
        let points: [(Double, CGFloat)] = [
            (200, 0.07), (165, 0.25), (140, 0.07), (112, 0.21), (90, 0.06),
            (68, 0.21), (40, 0.07), (15, 0.25), (-20, 0.07)
        ]
        var path = Path()
        for (index, point) in points.enumerated() {
            let radians = point.0 * .pi / 180
            let location = CGPoint(x: center.x + cos(radians) * point.1 * rect.width,
                                   y: center.y - sin(radians) * point.1 * rect.height * 0.75)
            if index == 0 { path.move(to: location) } else { path.addLine(to: location) }
        }
        path.addQuadCurve(to: rect.point(0.43, 0.27), control: rect.point(0.5, 0.33))
        path.closeSubpath()
        return path
    }
}

/// Dial line with tick marks across the body.
struct PomoMarkDial: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: rect.point(0.14, 0.58))
        path.addLine(to: rect.point(0.86, 0.58))
        for index in 0..<7 {
            let x = 0.23 + CGFloat(index) * 0.09
            path.move(to: rect.point(x, 0.485))
            path.addLine(to: rect.point(x, 0.52))
        }
        return path
    }
}

/// Small pointer under the dial.
struct PomoMarkPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: rect.point(0.5, 0.64))
        path.addLine(to: rect.point(0.55, 0.72))
        path.addLine(to: rect.point(0.45, 0.72))
        path.closeSubpath()
        return path
    }
}

#Preview("Pomo mark") {
    HStack(spacing: 24) {
        PomoMark().frame(width: 120)
        PomoMark(tint: PomoPalette.shortBreak, leafTint: PomoPalette.focus).frame(width: 64)
        PomoMark(showsDial: false).frame(width: 24)
    }
    .padding()
}

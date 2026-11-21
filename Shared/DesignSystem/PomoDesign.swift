// Shared/DesignSystem/PomoDesign.swift
//
// Pomo design system ("Cocina"): tokens, the kitchen dial and the Pomo mark, shared by
// the iPhone app, the Watch app, the widgets and the Live Activity.
//
// Principles
// - A kitchen timer: the session's color fills the screen, a cream dial turns as time passes.
// - Few, warm colors: field, cream, ink and one small accent per session type.
// - Numbers are the hero: heavy rounded, monospaced digits for every time value.
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
    static let l: CGFloat = 22
    static let xl: CGFloat = 30
}

extension Color {
    /// sRGB color from a 0xRRGGBB value (for brand colors that never change with appearance).
    init(pomoHex hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// "Cocina" palette: a tomato-red timer body, a cream dial, dark ink and a leaf-green accent.
/// Each session type has its own field color so the mode is obvious at a glance.
enum PomoPalette {
    /// Focus field: tomato.
    static let focus = Color("PomoPrimary")
    /// Short break field: deep teal.
    static let shortBreak = Color("PomoSecondary")
    /// Long break field: indigo.
    static let longBreak = Color("PomoLongBreak")

    /// Dial face and text on colored fields.
    static let cream = Color(pomoHex: 0xFFF4E6)
    /// Primary button and dial numbers.
    static let ink = Color(pomoHex: 0x2B1714)
    /// Tomato stem: the focus accent.
    static let leaf = Color(pomoHex: 0x2F9E62)

    /// Page behind cards (warm cream; warm near-black in Dark Mode).
    static let background = Color("PomoBackground")
    /// Cards.
    static let surface = Color("PomoSurface")
    /// Card outlines and separators.
    static let hairline = Color("PomoHairline")
    /// Secondary text on the page.
    static let muted = Color("PomoMuted")
    /// Tab bar and grouped controls on the page.
    static let chrome = Color("PomoChrome")
    /// Primary text on the page.
    static let inkText = Color("PomoInkText")
    /// Outline of the white secondary buttons.
    static let buttonOutline = Color(pomoHex: 0xEAD8C6)
}

extension TimerType {
    /// Field color of this session type.
    var tint: Color {
        switch self {
        case .work: return PomoPalette.focus
        case .shortBreak: return PomoPalette.shortBreak
        case .longBreak: return PomoPalette.longBreak
        }
    }

    /// Small accent that pairs with the field (pointer, dots).
    var accent: Color {
        switch self {
        case .work: return PomoPalette.leaf
        case .shortBreak: return Color(pomoHex: 0xF07A5F)
        case .longBreak: return Color(pomoHex: 0xF2B544)
        }
    }

    /// Remaining-time band painted on the dial.
    var wedge: Color {
        switch self {
        case .work: return Color(pomoHex: 0xF9CDB9)
        case .shortBreak: return Color(pomoHex: 0xC4E8E1)
        case .longBreak: return Color(pomoHex: 0xD5D6F3)
        }
    }

    /// Secondary text on the field.
    var onFieldSecondary: Color {
        switch self {
        case .work: return Color(pomoHex: 0xFFE1D2)
        case .shortBreak: return Color(pomoHex: 0xD6F1EC)
        case .longBreak: return Color(pomoHex: 0xE0E1FA)
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
    /// Heavy rounded digits for the hero time.
    static func pomoNumber(size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Rounded text style that follows Dynamic Type.
    static func pomoRounded(_ style: Font.TextStyle, weight: Font.Weight = .heavy) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

// MARK: - Kitchen dial

/// The signature element: a cream kitchen-timer dial that turns as time passes. The minute
/// under the pointer is the time left; the tinted band shows the minutes still to go.
/// Draw it inside a frame whose top is where the dial starts; it extends (and is clipped)
/// below like a large physical dial.
struct KitchenDial: View {
    /// Seconds left in the session.
    var remaining: Double
    /// Planned session length in seconds.
    var total: Double
    var type: TimerType
    /// Dial radius as a fraction of the available width.
    var radiusRatio: CGFloat = 0.82
    /// Space above the dial for the pointer.
    var pointerSpace: CGFloat = 22
    var showsLabels = true
    /// How the dial turns when `remaining` changes: one second at a time while running,
    /// quicker while the user drags the length.
    var turnAnimation: Animation = .linear(duration: 1)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var totalMinutes: Double { max(1, total / 60) }
    /// Short sessions spread wider so each minute stays readable.
    private var degreesPerMinute: Double { totalMinutes <= 10 ? 24 : 6 }
    private var currentMinutes: Double { max(0, remaining / 60) }

    var body: some View {
        GeometryReader { proxy in
            let radius = proxy.size.width * radiusRatio
            let center = CGPoint(x: proxy.size.width / 2, y: pointerSpace + radius)
            let scale = radius / 330

            ZStack {
                Circle()
                    .fill(PomoPalette.ink.opacity(0.18))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: center.x, y: center.y + 12 * scale)

                Circle()
                    .fill(PomoPalette.cream)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                ZStack {
                    DialBand(sweepDegrees: currentMinutes * degreesPerMinute, innerRatio: 0.8)
                        .fill(type.wedge)
                    DialFace(maxMinutes: Int(totalMinutes.rounded(.up)) + 5,
                             degreesPerMinute: degreesPerMinute,
                             tint: type.tint,
                             showsLabels: showsLabels,
                             scale: scale,
                             labelRotation: currentMinutes * degreesPerMinute)
                }
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-currentMinutes * degreesPerMinute))
                .animation(reduceMotion ? nil : turnAnimation, value: remaining)
                .position(center)

                DialPointer()
                    .fill(type.accent)
                    .frame(width: 22 * scale + 6, height: 20 * scale + 4)
                    .position(x: center.x, y: pointerSpace - (10 * scale + 2))
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Band from the zero mark (top) clockwise to `sweepDegrees`, in the dial's own frame.
struct DialBand: Shape {
    var sweepDegrees: Double
    var innerRatio: CGFloat

    var animatableData: Double {
        get { sweepDegrees }
        set { sweepDegrees = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let sweep = max(0, min(359, sweepDegrees))
        guard sweep > 0 else { return Path() }

        func point(_ degrees: Double, _ radius: CGFloat) -> CGPoint {
            let radians = degrees * .pi / 180
            return CGPoint(x: center.x + CGFloat(sin(radians)) * radius, y: center.y - CGFloat(cos(radians)) * radius)
        }

        var path = Path()
        path.move(to: point(0, outer))
        var angle = 0.0
        while angle < sweep {
            angle = min(sweep, angle + 1)
            path.addLine(to: point(angle, outer))
        }
        while angle > 0 {
            path.addLine(to: point(angle, inner))
            angle = max(0, angle - 1)
        }
        path.addLine(to: point(0, inner))
        path.closeSubpath()
        return path
    }
}

/// Minute ticks and numbers, minute 0 at the top, increasing clockwise. Short sessions get
/// quarter-minute ticks. Numbers are counter-rotated so they stay upright as the dial turns.
struct DialFace: View {
    let maxMinutes: Int
    let degreesPerMinute: Double
    let tint: Color
    let showsLabels: Bool
    let scale: CGFloat
    /// The dial's current rotation, undone on each number.
    var labelRotation: Double = 0

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let isShort = degreesPerMinute >= 12
            let ticksPerMinute = isShort ? 4 : 1
            let labelEvery = isShort ? 1 : 5
            for index in 0...(max(0, maxMinutes) * ticksPerMinute) {
                let minute = Double(index) / Double(ticksPerMinute)
                let degrees = minute * degreesPerMinute
                guard degrees < 360 else { break }
                let radians = degrees * .pi / 180
                let isWholeMinute = index % ticksPerMinute == 0
                let major = isWholeMinute && Int(minute) % labelEvery == 0
                let length = (major ? 24 : (isWholeMinute ? 16 : 10)) * scale
                let start = CGPoint(x: center.x + CGFloat(sin(radians)) * radius,
                                    y: center.y - CGFloat(cos(radians)) * radius)
                let end = CGPoint(x: center.x + CGFloat(sin(radians)) * (radius - length),
                                  y: center.y - CGFloat(cos(radians)) * (radius - length))
                var tick = Path()
                tick.move(to: start)
                tick.addLine(to: end)
                context.stroke(tick, with: .color(tint.opacity(major ? 1 : (isWholeMinute ? 0.7 : 0.4))),
                               style: StrokeStyle(lineWidth: (major ? 3 : 2) * max(scale, 0.6), lineCap: .round))

                if showsLabels && major {
                    let labelRadius = radius - 50 * scale
                    let position = CGPoint(x: center.x + CGFloat(sin(radians)) * labelRadius,
                                           y: center.y - CGFloat(cos(radians)) * labelRadius)
                    var layer = context
                    layer.translateBy(x: position.x, y: position.y)
                    layer.rotate(by: .degrees(labelRotation))
                    layer.draw(Text("\(Int(minute))")
                                .font(.system(size: 18 * scale, weight: .black, design: .rounded))
                                .foregroundColor(PomoPalette.ink),
                               at: .zero)
                }
            }
        }
    }
}

/// Downward triangle marking the time left.
struct DialPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
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

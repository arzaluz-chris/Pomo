// Core/Features/Timer/Views/CircularProgressView.swift

import SwiftUI

/// Timer ring: a quiet track with the elapsed part in the session's color and 12 hour-like ticks.
struct CircularProgressView: View {
    let progress: Double
    var tint: Color = PomoPalette.focus
    var lineWidth: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(PomoPalette.surface.opacity(0.7))
                .padding(lineWidth * 1.5)
                .shadow(color: .black.opacity(0.05), radius: 16, y: 8)

            ticks
                .padding(lineWidth * 2.4)

            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
        }
        .padding(lineWidth / 2)
        .accessibilityHidden(true)
    }

    private var ticks: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Capsule()
                        .fill(Color.primary.opacity(index % 3 == 0 ? 0.22 : 0.1))
                        .frame(width: 2, height: index % 3 == 0 ? 10 : 6)
                        .offset(y: -side / 2 + 5)
                        .rotationEffect(.degrees(Double(index) * 30))
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

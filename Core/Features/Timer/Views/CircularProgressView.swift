// Core/Features/Timer/Views/CircularProgressView.swift

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var tint: Color = .pomoPrimary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: Constants.UI.timerStrokeWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: Constants.UI.timerStrokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.5), radius: 8)
                .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
        }
        .accessibilityHidden(true)
    }
}

// PomoWatch/Views/WatchCircularProgressView.swift

import SwiftUI

struct WatchCircularProgressView: View {
    let progress: Double
    var tint: Color = .pomoPrimary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.25),
                        style: StrokeStyle(lineWidth: Constants.WatchUI.strokeWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: Constants.WatchUI.strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
        }
        .accessibilityHidden(true)
    }
}

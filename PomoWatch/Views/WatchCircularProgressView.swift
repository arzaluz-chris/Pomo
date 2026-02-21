// PomoWatch/Views/WatchCircularProgressView.swift

import SwiftUI

struct WatchCircularProgressView: View {
    let progress: Double

    var body: some View {
        if #available(watchOS 26, *) {
            ZStack {
                // Background ring with depth effect
                Circle()
                    .stroke(
                        Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: Constants.WatchUI.strokeWidth, lineCap: .round)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 3, y: 3)

                // Progress ring with gradient and glow
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.pomoPrimary.opacity(0.8), .pomoSecondary]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(
                            lineWidth: Constants.WatchUI.strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .pomoPrimary.opacity(0.5), radius: 6, x: 0, y: 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
            }
        } else {
            // Standard dark design for pre-watchOS 26
            ZStack {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: Constants.WatchUI.strokeWidth
                    )

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.pomoPrimary,
                        style: StrokeStyle(
                            lineWidth: Constants.WatchUI.strokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }
        }
    }
}

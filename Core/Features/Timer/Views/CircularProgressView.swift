// CircularProgressView.swift

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color.pomoSecondary.opacity(0.2),
                    lineWidth: Constants.UI.timerStrokeWidth
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.pomoPrimary,
                    style: StrokeStyle(
                        lineWidth: Constants.UI.timerStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

#Preview {
    CircularProgressView(progress: 0.75)
        .frame(width: 200, height: 200)
}

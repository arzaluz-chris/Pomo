import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.pomoSecondary.opacity(0.2), lineWidth: Constants.UI.timerStrokeWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.pomoPrimary,
                    style: StrokeStyle(lineWidth: Constants.UI.timerStrokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .shadow(color: Color.pomoPrimary.opacity(0.6), radius: 8)
        }
        .glassEffect(in: Circle())
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

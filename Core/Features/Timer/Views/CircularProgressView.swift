// Core/Features/Timer/Views/CircularProgressView.swift

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        if #available(iOS 26, *) {
            ZStack {
                // Anillo de fondo con efecto de profundidad.
                Circle()
                    .stroke(
                        Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: Constants.UI.timerStrokeWidth, lineCap: .round)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 5, y: 5)

                // Anillo de progreso con degradado y brillo.
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.pomoPrimary.opacity(0.8), .pomoSecondary]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(
                            lineWidth: Constants.UI.timerStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .pomoPrimary.opacity(0.6), radius: 10, x: 0, y: 0) // Efecto de brillo
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
            }
        } else {
            // CÓDIGO ORIGINAL (sin cambios)
            ZStack {
                Circle()
                    .stroke(
                        Color.pomoSecondary.opacity(0.2),
                        lineWidth: Constants.UI.timerStrokeWidth
                    )
                
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
}

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme  // <-- Aquí agregamos el colorScheme

    var body: some View {
        ZStack {
            // Fondo Liquid Glass (puedes conservar tu color pomoBackground si deseas)
            LinearGradient(
                colors: [Color.pomoPrimary.opacity(0.5), Color.pomoPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header con App Icon dinámico
                HStack(spacing: 12) {
                    Image(colorScheme == .dark ? "PomoLogoDark" : "PomoLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    Text("Pomo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pomoPrimary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                HStack(spacing: 20) {
                    ForEach([TimerType.work, .shortBreak], id: \.self) { type in
                        Button(action: {
                            viewModel.changeTimerType(to: type)
                        }) {
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(viewModel.currentType == type ? .bold : .regular)
                                .foregroundColor(viewModel.currentType == type ? .white : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .disabled(viewModel.isActive)
                        .glassEffect(in: Capsule(), isEnabled: viewModel.currentType == type)
                    }
                }
                .opacity(viewModel.isActive ? 0.6 : 1.0)
                
                ZStack {
                    CircularProgressView(progress: viewModel.progress)
                    VStack(spacing: 8) {
                        Text(viewModel.timeString)
                            .font(.system(size: 48, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                        Text(viewModel.currentType.displayName)
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                }
                .frame(width: Constants.UI.timerCircleSize, height: Constants.UI.timerCircleSize)
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleTimer()
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                                .font(.title2)
                            Text(viewModel.buttonTitle)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.UI.buttonHeight)
                    .buttonStyle(.glass)
                    .tint(.pomoPrimary)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.resetTimer()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise").font(.body)
                                Text("Reiniciar").font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .buttonStyle(.glass)
                        .tint(.gray)
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        
                        if viewModel.isActive {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.skipSession()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "forward.fill").font(.body)
                                    Text("Saltar").font(.subheadline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .buttonStyle(.glass)
                            .tint(.gray)
                            .foregroundColor(.primary)
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            viewModel.dataService.setModelContext(modelContext)
        }
    }
}

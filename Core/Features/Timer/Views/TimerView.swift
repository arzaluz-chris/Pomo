// TimerView.swift

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Color.pomoBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header with App Icon
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
                
                // Session Type Selector
                HStack(spacing: 20) {
                    ForEach([TimerType.work, .shortBreak], id: \.self) { type in
                        Button(action: {
                            viewModel.changeTimerType(to: type)
                        }) {
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(viewModel.currentType == type ? .bold : .regular)
                                .foregroundColor(viewModel.currentType == type ? .pomoPrimary : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.currentType == type ? Color.pomoPrimary.opacity(0.2) : Color.clear)
                                )
                        }
                        .disabled(viewModel.isActive) // Deshabilitar cambio durante timer activo
                    }
                }
                .opacity(viewModel.isActive ? 0.6 : 1.0)
                
                // Timer Circle
                ZStack {
                    CircularProgressView(progress: viewModel.progress)
                    
                    VStack(spacing: 8) {
                        Text(viewModel.timeString)
                            .font(.system(size: 48, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.pomoPrimary)
                        
                        Text(viewModel.currentType.displayName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: Constants.UI.timerCircleSize, height: Constants.UI.timerCircleSize)
                
                // Control Buttons
                VStack(spacing: 16) {
                    // Main button (Play/Pause)
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
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.buttonHeight)
                        .background(Color.pomoPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                    }
                    
                    // Secondary buttons
                    HStack(spacing: 16) {
                        // Reset button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.resetTimer()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.body)
                                Text("Reiniciar")
                                    .font(.subheadline)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(22)
                        }
                        
                        // Skip button (only when active)
                        if viewModel.isActive {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.skipSession()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "forward.fill")
                                        .font(.body)
                                    Text("Saltar")
                                        .font(.subheadline)
                                        .minimumScaleFactor(0.8)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(22)
                            }
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

#Preview {
    TimerView()
        .modelContainer(for: TimerSession.self, inMemory: true)
}

// Core/Features/Timer/Views/TimerView.swift

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if #available(iOS 26, *) {
            ZStack {
                // FONDO LÍQUIDO: Un degradado animado con un desenfoque de fondo.
                LinearGradient(
                    gradient: Gradient(colors: [Color.pomoPrimary.opacity(0.3), Color.pomoSecondary.opacity(0.4), .blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blur(radius: 60)

                VStack(spacing: 30) {
                    Text("🍅 Pomo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 40)

                    Spacer()

                    // Selector de tipo de sesión con efecto de cristal.
                    HStack(spacing: 20) {
                        ForEach([TimerType.work, .shortBreak], id: \.self) { type in
                            Button(action: {
                                viewModel.changeTimerType(to: type)
                            }) {
                                Text(type.displayName)
                                    .fontWeight(viewModel.currentType == type ? .bold : .regular)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        .ultraThinMaterial,
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(viewModel.currentType == type ? Color.pomoPrimary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .disabled(viewModel.isActive)
                        }
                    }
                    .opacity(viewModel.isActive ? 0.6 : 1.0)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 30))
                    
                    // Círculo del temporizador con efecto de cristal.
                    ZStack {
                        CircularProgressView(progress: viewModel.progress)
                        
                        VStack(spacing: 8) {
                            Text(viewModel.timeString)
                                .font(.system(size: 52, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                            
                            Text(viewModel.currentType.displayName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: Constants.UI.timerCircleSize, height: Constants.UI.timerCircleSize)
                    .padding(20)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                    // Botones de control con nuevo diseño.
                    VStack(spacing: 16) {
                        Button(action: {
                            withAnimation(.spring()) {
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
                            .clipShape(Capsule())
                            .shadow(color: .pomoPrimary.opacity(0.5), radius: 10, y: 5)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: { viewModel.resetTimer() }) {
                                Text("Reiniciar")
                                    .frame(maxWidth: .infinity)
                            }
                            
                            if viewModel.isActive {
                                Button(action: { viewModel.skipSession() }) {
                                    Text("Saltar")
                                        .frame(maxWidth: .infinity)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                viewModel.dataService.setModelContext(modelContext)
            }
        } else {
            // CÓDIGO ORIGINAL (sin cambios)
            ZStack {
                Color.pomoBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("🍅 Pomo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pomoPrimary)
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
                                    .foregroundColor(viewModel.currentType == type ? .pomoPrimary : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.currentType == type ? Color.pomoPrimary.opacity(0.2) : Color.clear)
                                    )
                            }
                            .disabled(viewModel.isActive)
                        }
                    }
                    .opacity(viewModel.isActive ? 0.6 : 1.0)
                    
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
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.UI.buttonHeight)
                            .background(Color.pomoPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(Constants.UI.cornerRadius)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.resetTimer()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.body)
                                    Text("Reiniciar")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(22)
                            }
                            
                            if viewModel.isActive {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.skipSession()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "forward.fill")
                                            .font(.body)
                                        Text("Saltar")
                                            .font(.subheadline)
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
}

#Preview {
    TimerView()
        .modelContainer(for: TimerSession.self, inMemory: true)
}

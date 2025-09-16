// Core/Features/Timer/Views/TimerView.swift

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.modelContext) private var modelContext
    @Namespace private var selectionAnimation
    
    // Estado para controlar el color de fondo animado
    @State private var backgroundGradient = Gradient(colors: [Color.pomoPrimary.opacity(0.3), Color.pomoSecondary.opacity(0.4), .blue.opacity(0.3)])

    var body: some View {
        if #available(iOS 26, *) {
            ZStack {
                // FONDO LÍQUIDO ANIMADO
                LinearGradient(
                    gradient: backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blur(radius: 60)
                .animation(.easeInOut(duration: 0.8), value: viewModel.isActive)

                // --- CAMBIO ESTRUCTURAL: Se usa VStack con Spacers para controlar la distribución vertical ---
                VStack(spacing: 0) {
                    
                    // --- ANIMACIÓN: El título y el switch solo aparecen si el timer NO está activo ---
                    if !viewModel.isActive {
                        HStack(spacing: 8) {
                            Image("AppIcon-Symbol")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            
                            Text("Pomo")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 40)
                        
                        Spacer()

                        let sessionTypes: [TimerType] = [.work, .shortBreak]
                        HStack(spacing: 0) {
                            ForEach(sessionTypes, id: \.self) { type in
                                ZStack {
                                    if viewModel.currentType == type {
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2)
                                            .matchedGeometryEffect(id: "selectionBackground", in: selectionAnimation)
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7)) {
                                            viewModel.changeTimerType(to: type)
                                        }
                                    }) {
                                        Text(type.displayName)
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundColor(viewModel.currentType == type ? .pomoPrimary : .secondary)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .background(.thinMaterial.opacity(0.7), in: Capsule())
                        .frame(width: 150, height: 40)
                        .transition(.opacity) // Transición sutil para el switch
                    }
                    
                    // Spacer para empujar el círculo hacia el centro
                    Spacer()

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

                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            // La animación principal se dispara aquí
                            withAnimation(.easeInOut(duration: 0.8)) {
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
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.8)) { // La vista vuelve a la normalidad con animación
                                    viewModel.resetTimer()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reiniciar")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            if viewModel.isActive {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.8)) { // La vista vuelve a la normalidad con animación
                                        viewModel.skipSession()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "forward.fill")
                                        Text("Saltar")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .controlSize(.regular)
                    }
                    .padding(.horizontal, 40)
                    
                }
                .padding(.bottom, 40)
            }
            .onAppear {
                viewModel.dataService.setModelContext(modelContext)
            }
            .onChange(of: viewModel.isActive) { isActive in
                if isActive {
                    // Gradiente para el modo enfoque con los colores de la app
                    self.backgroundGradient = Gradient(colors: [Color.pomoSecondary.opacity(0.5), Color.pomoPrimary.opacity(0.4)])
                } else {
                    // Gradiente original
                    self.backgroundGradient = Gradient(colors: [Color.pomoPrimary.opacity(0.3), Color.pomoSecondary.opacity(0.4), .blue.opacity(0.3)])
                }
            }
        } else {
            // CÓDIGO ORIGINAL
            // ...
        }
    }
}

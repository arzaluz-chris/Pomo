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
            // CÓDIGO ORIGINAL PARA iOS 18 Y ANTERIORES
            ZStack {
                // Background
                Color.pomoBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    Text("🍅 Pomo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.pomoPrimary)
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
                            
                            // Skip button (only when active)
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

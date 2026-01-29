import SwiftUI
import PadelCore

struct WatchScoringView: View {
    @State var viewModel = MatchViewModel()
    
    var body: some View {
        Group {
            if !viewModel.isMatchStarted {
                MatchSettingsView(viewModel: viewModel) {
                    withAnimation(.spring()) {
                        viewModel.startMatch()
                    }
                }
            } else {
                TabView {
                    // Page 1: Scoring
                VStack(spacing: 2) {
                    // Header Area: Sets info (Pushed down from clock)
                    HStack(spacing: 8) {
                        Text("\(viewModel.state.team1Sets)")
                            .foregroundColor(.green)
                        Text("-")
                        Text("\(viewModel.state.team2Sets)")
                            .foregroundColor(.blue)
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .padding(.top, 24)
                    
                    // Main Scoring Area
                    HStack(spacing: 4) {
                        ScoreColumn(
                            team: "T1",
                            score: viewModel.state.isTieBreak ? "\(viewModel.state.team1TieBreakPoints)" : viewModel.state.team1Score.rawValue,
                            isServing: viewModel.state.servingTeam == 1,
                            color: .green,
                            onTap: { viewModel.scorePoint(forTeam1: true) }
                        )
                        
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 4, height: 4)
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 4, height: 4)
                        }
                        
                        ScoreColumn(
                            team: "T2",
                            score: viewModel.state.isTieBreak ? "\(viewModel.state.team2TieBreakPoints)" : viewModel.state.team2Score.rawValue,
                            isServing: viewModel.state.servingTeam == 2,
                            color: .blue,
                            onTap: { viewModel.scorePoint(forTeam1: false) }
                        )
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Footer Area: Games + Undo
                    VStack(spacing: 8) { // Increased spacing from 4 to 8
                        Text(viewModel.state.isTieBreak ? "TIE BREAK" : "GAMES: \(viewModel.state.team1Games)-\(viewModel.state.team2Games)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(viewModel.state.isTieBreak ? .yellow : .secondary)
                            .padding(.bottom, 2) // Extra nudge up
                        
                        Button(action: { viewModel.undoPoint() }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .black))
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                                .background(viewModel.canUndo ? Color.orange.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(14)
                                .foregroundColor(viewModel.canUndo ? .orange : .secondary.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canUndo)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 2)
                }
                .containerBackground(Color.black.gradient, for: .navigation)
                    .tag(0)
                    
                    // Page 2: Controls
                    WatchControlsView(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(.verticalPage)
                .navigationTitle("Padel Score")
                .transition(.opacity)
                .overlay(alignment: .top) {
                    if let label = specialPointLabel {
                        SpecialPointIndicator(label: label)
                            .padding(.top, 8)
                    }
                }
                .onChange(of: specialPointLabel) { _, new in
                    if new != nil {
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.notification)
                        #endif
                    }
                }
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { viewModel.state.isMatchOver },
            set: { if !$0 { viewModel.resetMatch() } }
        )) {
            MatchSummaryView(state: viewModel.state) {
                viewModel.resetMatch()
            }
        }
    }
    
    private var specialPointLabel: String? {
        let state = viewModel.state
        guard state.team1Score == .forty && state.team2Score == .forty else { return nil }
        
        switch state.scoringSystem {
        case .goldenPoint:
            return "GOLDEN POINT"
        case .starPoint:
            if state.deuceCount >= 3 {
                return "STAR POINT"
            }
        case .standard:
            return nil
        }
        return nil
    }
}

struct SpecialPointIndicator: View {
    let label: String
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        Text(label)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .tracking(1.5) // Premium character spacing
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                ZStack {
                    // Pulsing Glow Aura behind the text
                    Capsule()
                        .fill(themeColor)
                        .blur(radius: 8)
                        .opacity(glowOpacity)
                        .scaleEffect(pulseScale * 1.2)
                    
                    // Glassmorphism base (using ultraThinMaterial for integration)
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    // Subtle glowing border
                    Capsule()
                        .strokeBorder(themeColor.opacity(0.6), lineWidth: 0.5)
                }
            }
            .scaleEffect(pulseScale)
            .onAppear {
                // Slower, more elegant pulse for premium feel
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulseScale = 1.06
                    glowOpacity = 0.6
                }
            }
            .onDisappear {
                pulseScale = 1.0
                glowOpacity = 0.3
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                removal: .opacity.combined(with: .scale(scale: 0.5))
            ))
    }
    
    private var themeColor: Color {
        label.contains("STAR") ? .orange : .yellow
    }
}

struct ScoreColumn: View {
    let team: String
    let score: String
    let isServing: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    if isServing {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 4, height: 4)
                    }
                    Text(team.prefix(6))
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(isServing ? .yellow : .secondary.opacity(0.8))
                    if isServing {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 4, height: 4)
                    }
                }
                
                ZStack {
                    if score == "AD" {
                        Text(score)
                            .font(.system(size: 130, weight: .black, design: .rounded))
                            .foregroundColor(color)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                    } else {
                        Text(score)
                            .font(.system(size: 180, weight: .black, design: .rounded))
                            .foregroundColor(color)
                            .scaleEffect(x: 0.85, y: 1.15)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                    }
                }
                .frame(height: 120) // Anchor the height to prevent shifts
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.spring(), value: isServing)
    }
}


#Preview {
    WatchScoringView()
}

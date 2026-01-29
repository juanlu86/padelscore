import SwiftUI
import PadelCore

struct iPhoneMatchView: View {
    @State var viewModel = MatchViewModel()
    private let haptics = UISelectionFeedbackGenerator()
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                Color.black.ignoresSafeArea()
                
                // Dynamic Background Flare
                RadialGradient(
                    colors: [viewModel.state.isMatchOver ? (calculateTeamWinner() == 1 ? .green.opacity(0.15) : .blue.opacity(0.15)) : .yellow.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // PadelPro Header
                    PadelProHeader(syncStatus: viewModel.syncStatus)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Primary Score Board
                            VStack(spacing: 20) {
                                HStack(spacing: 12) {
                                    GlassScoreCard(
                                        name: viewModel.state.team1,
                                        score: viewModel.team1DisplayScore,
                                        games: viewModel.state.team1Games,
                                        sets: viewModel.state.team1Sets,
                                        isServing: viewModel.state.servingTeam == 1,
                                        hasWon: viewModel.state.isMatchOver && calculateTeamWinner() == 1,
                                        color: .green,
                                        onTap: { 
                                            impact.impactOccurred()
                                            viewModel.scorePoint(forTeam1: true) 
                                        }
                                    )
                                    
                                    vsIndicator
                                    
                                    GlassScoreCard(
                                        name: viewModel.state.team2,
                                        score: viewModel.team2DisplayScore,
                                        games: viewModel.state.team2Games,
                                        sets: viewModel.state.team2Sets,
                                        isServing: viewModel.state.servingTeam == 2,
                                        hasWon: viewModel.state.isMatchOver && calculateTeamWinner() == 2,
                                        color: .blue,
                                        onTap: { 
                                            impact.impactOccurred()
                                            viewModel.scorePoint(forTeam1: false) 
                                        }
                                    )
                                }
                            }
                            .padding(20)
                            .background(.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(.white.opacity(0.05), lineWidth: 1)
                            )
                            
                            // Quick Controls
                            VStack(alignment: .leading, spacing: 16) {
                                Text("QUICK ACTIONS")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                
                                HStack(spacing: 12) {
                                    ProActionButton(title: "RESET", icon: "arrow.counterclockwise", color: .red) {
                                        haptics.selectionChanged()
                                        viewModel.resetMatch()
                                    }
                                    
                                    ProActionButton(title: "UNDO", icon: "arrow.uturn.backward", color: .orange) {
                                        haptics.selectionChanged()
                                        viewModel.undoPoint()
                                    }
                                    .disabled(!viewModel.canUndo)
                                    .opacity(viewModel.canUndo ? 1.0 : 0.3)
                                    
                                    ProActionButton(title: "FINISH", icon: "checkmark.circle", color: .green) {
                                        impact.impactOccurred(intensity: 1.0)
                                        viewModel.finishMatch()
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .toolbar(.hidden) // We use our custom header
            .alert("Sync Failed", isPresented: Binding(
                get: { if case .failed = viewModel.syncStatus { return true } else { return false } },
                set: { if !$0 { SyncService.shared.status = .idle } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let message) = viewModel.syncStatus {
                    Text(message)
                }
            }
            
            // Settings Overlay
            if !viewModel.isMatchStarted {
                MatchSettingsView(viewModel: viewModel) {
                    withAnimation(.spring()) {
                        impact.impactOccurred()
                        viewModel.startMatch()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { viewModel.state.isMatchOver },
            set: { if !$0 && viewModel.state.isMatchOver { viewModel.resetMatch() } }
        )) {
            MatchSummaryView(
                state: viewModel.state,
                onUndo: { viewModel.undoPoint() },
                onDismiss: { viewModel.resetMatch() }
            )
        }
        .overlay(alignment: .top) {
            if let label = viewModel.specialPointLabel {
                SpecialPointIndicator(label: label)
                    .padding(.top, 140)
            }
        }
    }
    
    private var vsIndicator: some View {
        VStack(spacing: 4) {
            if viewModel.state.isTieBreak {
                Text("TIE-BREAK")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.yellow)
                    .transition(.scale)
            }
            Text("VS")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white.opacity(0.15))
        }
        .frame(width: 40)
    }
    
    private func calculateTeamWinner() -> Int {
        let t1Sets = viewModel.state.team1Sets
        let t2Sets = viewModel.state.team2Sets
        if t1Sets > t2Sets { return 1 }
        if t2Sets > t1Sets { return 2 }
        return 0
    }
}

// MARK: - Pro Components

struct PadelProHeader: View {
    let syncStatus: SyncService.Status
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PADELSCORE PRO")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.zinc400)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: statusColor.opacity(0.5), radius: 2)
                    
                    Text(statusLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.zinc500)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                syncBadge
                
                Text("COURT 1")
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.05))
                    .clipShape(Capsule())
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 12)
    }
    
    private var statusColor: Color {
        if case .failed = syncStatus { return .red }
        return .yellow
    }
    
    private var statusLabel: String {
        if case .failed = syncStatus { return "SYNC ERROR" }
        return "LIVE FROM COURT"
    }
    
    private var syncBadge: some View {
        Group {
            switch syncStatus {
            case .idle:
                Image(systemName: "cloud")
                    .font(.system(size: 12))
                    .foregroundColor(.zinc500)
            case .syncing:
                ProgressView()
                    .controlSize(.small)
                    .tint(.yellow)
            case .synced:
                Image(systemName: "cloud.checkmark.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            case .failed(_):
                Image(systemName: "cloud.badge.exclamationmark.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

struct GlassScoreCard: View {
    let name: String
    let score: String
    let games: Int
    let sets: Int
    let isServing: Bool
    let hasWon: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onTap) {
                ZStack {
                    // Glass Background
                    Circle()
                        .fill(.white.opacity(0.05))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .overlay {
                            // Inner Glow if serving
                            if isServing {
                                Circle()
                                    .stroke(color.opacity(0.3), lineWidth: 4)
                                    .blur(radius: 4)
                            }
                        }
                    
                    // Score Text
                    Text(score)
                        .font(.system(size: score == "AD" ? 44 : 64, weight: .black, design: .rounded))
                        .foregroundColor(isServing ? .white : .white.opacity(0.7))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                }
                .overlay(alignment: .topTrailing) {
                    // Ball Indicator
                    if isServing {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(.black, lineWidth: 5)
                            )
                            .shadow(color: .yellow.opacity(0.5), radius: 8)
                            .offset(x: -8, y: 8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(ScoreButtonStyle())
            
            VStack(spacing: 6) {
                Text(name.isEmpty ? "TEAM" : name.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isServing || hasWon ? .white : .zinc500)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                if hasWon {
                    Text("WINNER")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.yellow)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 8) {
                        setGameBadge(label: "S", value: sets)
                        setGameBadge(label: "G", value: games)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isServing)
    }
    
    private func setGameBadge(label: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.zinc500)
            Text("\(value)")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.white.opacity(0.05))
        .clipShape(Capsule())
    }
}

struct ProActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                Text(title)
                    .font(.system(size: 8, weight: .black))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.white.opacity(0.05))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Helpers & Styles

extension Color {
    static let zinc400 = Color(white: 0.6)
    static let zinc500 = Color(white: 0.4)
    static let zinc800 = Color(white: 0.15)
    static let padelDark = Color(white: 0.05)
}

struct ScoreButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

#Preview {
    iPhoneMatchView()
        .preferredColorScheme(.dark)
}

struct SpecialPointIndicator: View {
    let label: String
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .tracking(2.0)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background {
                ZStack {
                    Capsule()
                        .fill(themeColor)
                        .blur(radius: 12)
                        .opacity(glowOpacity)
                        .scaleEffect(pulseScale * 1.3)
                    
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    Capsule()
                        .strokeBorder(themeColor.opacity(0.6), lineWidth: 1)
                }
            }
            .scaleEffect(pulseScale)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                    glowOpacity = 0.6
                }
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

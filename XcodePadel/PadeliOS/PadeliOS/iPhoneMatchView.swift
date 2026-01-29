import SwiftUI
import PadelCore

struct iPhoneMatchView: View {
    @State var viewModel = MatchViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Match Status Card
                        VStack(spacing: 16) {
                            HStack {
                                ScoreCardView(
                                    name: "Galán/Lebrón",
                                    score: viewModel.team1DisplayScore,
                                    games: viewModel.state.team1Games,
                                    sets: viewModel.state.team1Sets,
                                    isServing: viewModel.state.servingTeam == 1,
                                    color: .green,
                                    onTap: { viewModel.scorePoint(forTeam1: true) }
                                )
                                
                                vsIndicator
                                
                                ScoreCardView(
                                    name: "Coello/Tapia",
                                    score: viewModel.team2DisplayScore,
                                    games: viewModel.state.team2Games,
                                    sets: viewModel.state.team2Sets,
                                    isServing: viewModel.state.servingTeam == 2,
                                    color: .blue,
                                    onTap: { viewModel.scorePoint(forTeam1: false) }
                                )
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        // Quick Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                CircularActionButton(title: "Reset Match", icon: "arrow.counterclockwise", color: .red) {
                                    viewModel.resetMatch()
                                }
                                
                                CircularActionButton(title: "Finish Match", icon: "checkmark.circle", color: .green) {
                                    viewModel.finishMatch()
                                }
                                
                                CircularActionButton(title: "Undo Point", icon: "arrow.uturn.backward", color: .orange) {
                                    viewModel.undoPoint()
                                }
                                .disabled(!viewModel.canUndo)
                                .opacity(viewModel.canUndo ? 1.0 : 0.5)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Match Manager")
                .background(Color(.systemBackground))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        syncIndicator
                    }
                }
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
                            viewModel.startMatch()
                        }
                    }
                    .transition(.move(edge: .bottom))
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
                        .padding(.top, 120)
                }
            }
        }
    }
    
    private var vsIndicator: some View {
        VStack {
            if viewModel.state.isTieBreak {
                Text("TIE-BREAK")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.yellow)
            }
            Text("VS")
                .font(.system(.headline, design: .default, weight: .black))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
    
    private var syncIndicator: some View {
        Group {
            switch viewModel.syncStatus {
            case .idle:
                Image(systemName: "cloud")
                    .foregroundColor(.secondary)
            case .syncing:
                ProgressView()
                    .controlSize(.small)
            case .synced:
                Image(systemName: "cloud.checkmark.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "cloud.badge.exclamationmark.fill")
                    .foregroundColor(.red)
            }
        }
        .symbolEffect(.bounce, value: viewModel.syncStatus)
    }
}

#Preview {
    iPhoneMatchView()
}

// MARK: - UI Components

struct ScoreCardView: View {
    let name: String
    let score: String
    let games: Int
    let sets: Int
    let isServing: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onTap) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 140.0, height: 140.0)
                        .overlay {
                            if score == "AD" {
                                Text(score)
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            } else {
                                Text(score)
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.4)
                                    .lineLimit(1)
                            }
                        }
                    
                    if isServing {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(Color.black, lineWidth: 3)
                            )
                            .shadow(radius: 4)
                            .offset(x: -4, y: 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(), value: isServing)
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack {
                    Text("Sets: \(sets)")
                    Text("•")
                    Text("Games: \(games)")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CircularActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
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

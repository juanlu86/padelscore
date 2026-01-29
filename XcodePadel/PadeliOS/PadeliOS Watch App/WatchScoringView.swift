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
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("UNDO")
                                    .font(.system(size: 10, weight: .black))
                            }
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

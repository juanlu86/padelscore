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
                    VStack(spacing: 8) {
                        // Sets Header
                        HStack(spacing: 10) {
                            Text("Sets: \(viewModel.state.team1Sets)")
                            Text("-")
                            Text("\(viewModel.state.team2Sets)")
                        }
                        .font(.system(.caption2, weight: .bold))
                        .foregroundColor(.secondary)

                        // Scores Header
                        HStack(spacing: 12) {
                            ScoreColumn(
                                team: "Team 1",
                                score: viewModel.state.isTieBreak ? "\(viewModel.state.team1TieBreakPoints)" : viewModel.state.team1Score.rawValue,
                                color: .green,
                                onTap: { viewModel.scorePoint(forTeam1: true) }
                            )
                            Divider()
                            ScoreColumn(
                                team: "Team 2",
                                score: viewModel.state.isTieBreak ? "\(viewModel.state.team2TieBreakPoints)" : viewModel.state.team2Score.rawValue,
                                color: .blue,
                                onTap: { viewModel.scorePoint(forTeam1: false) }
                            )
                        }
                        .padding(.top, 2)
                        
                        // Sets/Games simple indicator
                        Text(viewModel.state.isTieBreak ? "TIE BREAK" : "Games: \(viewModel.state.team1Games) - \(viewModel.state.team2Games)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(viewModel.state.isTieBreak ? .yellow : .secondary)
                        
                        Spacer()
                        
                        // Undo Button (Full Width Pill)
                        Button(action: { viewModel.undoPoint() }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 18, weight: .black))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(viewModel.canUndo ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(18)
                                .foregroundColor(viewModel.canUndo ? .orange : .gray.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canUndo)
                        .padding(.horizontal, 4)
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
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(team.prefix(6)) // Abbreviate to T1/T2 style if needed
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.secondary.opacity(0.8))
                Text(score)
                    .font(.system(size: 180, weight: .black, design: .rounded))
                    .foregroundColor(color)
                    .scaleEffect(x: 0.85, y: 1.15) // Even more aggressive "tall" look
                    .minimumScaleFactor(0.4)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    WatchScoringView()
}

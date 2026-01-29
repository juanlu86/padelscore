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
                                TeamScoreCard(
                                    name: "Galán/Lebrón",
                                    score: viewModel.state.isTieBreak ? "\(viewModel.state.team1TieBreakPoints)" : viewModel.state.team1Score.rawValue,
                                    games: viewModel.state.team1Games,
                                    sets: viewModel.state.team1Sets,
                                    isServing: viewModel.state.servingTeam == 1,
                                    color: .green,
                                    onTap: { viewModel.scorePoint(forTeam1: true) }
                                )
                                
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
                                
                                TeamScoreCard(
                                    name: "Coello/Tapia",
                                    score: viewModel.state.isTieBreak ? "\(viewModel.state.team2TieBreakPoints)" : viewModel.state.team2Score.rawValue,
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
                                ActionButton(title: "Reset Match", icon: "arrow.counterclockwise", color: .red) {
                                    viewModel.resetMatch()
                                }
                                
                                ActionButton(title: "Finish Match", icon: "checkmark.circle", color: .green) {
                                    viewModel.finishMatch()
                                }
                                
                                ActionButton(title: "Undo Point", icon: "arrow.uturn.backward", color: .orange) {
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
                set: { if !$0 { viewModel.resetMatch() } }
            )) {
                MatchSummaryView(state: viewModel.state) {
                    viewModel.resetMatch()
                }
            }
        }
    }
}

struct TeamScoreCard: View {
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

struct ActionButton: View {
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

#Preview {
    iPhoneMatchView()
}

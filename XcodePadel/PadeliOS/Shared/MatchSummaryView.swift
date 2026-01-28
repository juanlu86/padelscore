import SwiftUI
import PadelCore

struct MatchSummaryView: View {
    let state: MatchState
    let onDismiss: () -> Void
    
    var winner: Int {
        state.team1Sets > state.team2Sets ? 1 : 2
    }
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.black.ignoresSafeArea()
            
            // Subtle Gradient Accent
            LinearGradient(
                colors: [Color.yellow.opacity(0.08), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compact Header
                HStack {
                    Text("Match result")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 24)
                .padding(.top, 15)
                .padding(.bottom, 8)
                
                // Compact Scoreboard (Glassmorphism)
                VStack(spacing: 0) {
                    ScoreboardRow(
                        label: "TEAM 1",
                        results: state.completedSets.map { $0.team1Games },
                        opponentResults: state.completedSets.map { $0.team2Games },
                        isMatchWinner: winner == 1
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    ScoreboardRow(
                        label: "TEAM 2",
                        results: state.completedSets.map { $0.team2Games },
                        opponentResults: state.completedSets.map { $0.team1Games },
                        isMatchWinner: winner == 2
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 12)
                
                Spacer()
                
                // Actions
                Button(action: onDismiss) {
                    Text("DONE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.yellow.gradient)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct ScoreboardRow: View {
    let label: String
    let results: [Int]
    let opponentResults: [Int]
    let isMatchWinner: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Team Label
            HStack(spacing: 8) {
                ZStack {
                    if isMatchWinner {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                .frame(width: 12)
                
                Text(label)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(isMatchWinner ? .white : .white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.leading, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Results
            HStack(spacing: 15) {
                ForEach(0..<max(3, results.count), id: \.self) { index in
                    let score = index < results.count ? results[index] : -1
                    let opponentScore = index < opponentResults.count ? opponentResults[index] : -1
                    
                    Text(score >= 0 ? "\(score)" : "–")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(score >= 0 ? (score > opponentScore ? .yellow : .white) : .white.opacity(0.15))
                        .frame(width: 25)
                }
            }
            .padding(.trailing, 15)
        }
        .frame(height: 60)
    }
}

#Preview {
    MatchSummaryView(state: MatchState(
        team1Sets: 2,
        team2Sets: 1,
        completedSets: [
            SetResult(team1Games: 6, team2Games: 4),
            SetResult(team1Games: 4, team2Games: 6),
            SetResult(team1Games: 7, team2Games: 5)
        ]
    ), onDismiss: {})
}

import SwiftUI
import PadelCore

struct WatchScoringView: View {
    @State var viewModel = MatchViewModel()
    
    var body: some View {
        VStack(spacing: 8) {
            // Scores Header
            HStack(spacing: 12) {
                ScoreColumn(team: "Team 1", score: viewModel.state.team1Score.rawValue, color: .green)
                Divider()
                ScoreColumn(team: "Team 2", score: viewModel.state.team2Score.rawValue, color: .blue)
            }
            .padding(.top, 4)
            
            // Sets/Games simple indicator
            Text("Games: \(viewModel.state.team1Games) - \(viewModel.state.team2Games)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                ScoreButton(color: .green) {
                    viewModel.scorePoint(forTeam1: true)
                }
                
                ScoreButton(color: .blue) {
                    viewModel.scorePoint(forTeam1: false)
                }
            }
        }
        .containerBackground(Color.black.gradient, for: .navigation)
        .navigationTitle("Padel Score")
    }
}

struct ScoreColumn: View {
    let team: String
    let score: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(team)
                .font(.system(.caption2, weight: .medium))
                .foregroundColor(.secondary)
            Text(score)
            .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScoreButton: View {
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44.0, height: 44.0)
                .foregroundStyle(.black, color.gradient)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WatchScoringView()
}

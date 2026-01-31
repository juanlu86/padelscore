import SwiftUI
import PadelCore

struct MatchScoreBoard: View {
    @Bindable var viewModel: MatchViewModel
    let impact: UIImpactFeedbackGenerator
    
    var body: some View {
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
        .padding(20)
        .background(.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        )
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

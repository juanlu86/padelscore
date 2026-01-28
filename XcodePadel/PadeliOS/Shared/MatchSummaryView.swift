import SwiftUI
import PadelCore

struct MatchSummaryView: View {
    let state: MatchState
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background - Dark Mode
            Rectangle()
                .fill(Color.black.gradient)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("MATCH COMPLETED")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.yellow) // High visibility highlight
                    .padding(.top, 40)
                
                // The Grid (TV Broadcast Style)
                VStack(spacing: 0) {
                    ScoreRow(name: "Galán/Lebrón", results: state.completedSets.map { $0.team1Games })
                    
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                    
                    ScoreRow(name: "Coello/Tapia", results: state.completedSets.map { $0.team2Games })
                }
                .padding(.vertical)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .padding(.horizontal)
                
                Spacer()
                
                // OK / Reset Button
                Button(action: onDismiss) {
                    Text("OK, START NEW MATCH")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow.gradient)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct ScoreRow: View {
    let name: String
    let results: [Int]
    
    var body: some View {
        HStack(spacing: 0) {
            Text(name.uppercased())
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
            
            HStack(spacing: 20) {
                ForEach(0..<3) { index in
                    Text(index < results.count ? "\(results[index])" : "-")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(index < results.count ? .white : .white.opacity(0.3))
                        .underline(index < results.count && isWinner(index: index))
                        .frame(width: 40)
                }
            }
            .padding(.trailing, 30)
        }
        .frame(height: 80)
    }
    
    private func isWinner(index: Int) -> Bool {
        // Logic to underline winning set would go here
        return false 
    }
}

#Preview {
    MatchSummaryView(state: MatchState(completedSets: [
        SetResult(team1Games: 5, team2Games: 7),
        SetResult(team1Games: 6, team2Games: 6),
        SetResult(team1Games: 2, team2Games: 3)
    ]), onDismiss: {})
}

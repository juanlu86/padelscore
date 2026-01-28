import SwiftUI

struct iPhoneMatchView: View {
    @State var viewModel = MatchViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Match Status Card
                    VStack(spacing: 16) {
                        HStack {
                            TeamScoreCard(name: "Galán/Lebrón", score: viewModel.state.team1Score.rawValue, games: viewModel.state.team1Games, color: .green)
                            
                            VStack {
                                Text("VS")
                                    .font(.system(.headline, weight: .black))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            
                            TeamScoreCard(name: "Coello/Tapia", score: viewModel.state.team2Score.rawValue, games: viewModel.state.team2Games, color: .blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(24)
                    
                    // Quick Controls
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            ActionButton(title: "Reset Match", icon: "arrow.counterclockwise", color: .red) {
                                viewModel.resetMatch()
                            }
                            
                            ActionButton(title: "Undo Point", icon: "arrow.uturn.backward", color: .orange) {
                                // Undo not implemented in logic yet
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Match Manager")
            .background(Color(.systemBackground))
        }
    }
}

struct TeamScoreCard: View {
    let name: String
    let score: String
    let games: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(color.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Text(score)
                        .font(.system(.title2, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("Games: \(games)")
                    .font(.caption2)
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
            .cornerRadius(16)
        }
    }
}

#Preview {
    iPhoneMatchView()
}

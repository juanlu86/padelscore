import SwiftUI
import PadelCore

struct MatchSummaryView: View {
    let state: MatchState
    let onUndo: () -> Void
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
            
            #if os(watchOS)
            ScrollView {
                mainContent
            }
            #else
            mainContent
            #endif
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Compact Header
            HStack {
                Text("Match result")
                    .font(.system(size: platformValue(watch: 12, ios: 16), weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Image(systemName: "circle.fill")
                    .font(.system(size: 4))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.top, platformValue(watch: 5, ios: 15))
            .padding(.bottom, 4)
            
            // Compact Scoreboard (Glassmorphism)
            VStack(spacing: 0) {
                ScoreboardRow(
                    label: "TEAM 1",
                    results: state.completedSets.map { $0.team1Games },
                    opponentResults: state.completedSets.map { $0.team2Games },
                    isMatchWinner: winner == 1,
                    isGrandSlam: state.isGrandSlam
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScoreboardRow(
                    label: "TEAM 2",
                    results: state.completedSets.map { $0.team2Games },
                    opponentResults: state.completedSets.map { $0.team1Games },
                    isMatchWinner: winner == 2,
                    isGrandSlam: state.isGrandSlam
                )
            }
            .background(
                RoundedRectangle(cornerRadius: platformValue(watch: 12, ios: 16))
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: platformValue(watch: 12, ios: 16))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 8)
            
            Spacer(minLength: platformValue(watch: 10, ios: 20))
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: platformValue(watch: 12, ios: 14), weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, platformValue(watch: 8, ios: 12))
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button(action: onDismiss) {
                    Text("DONE")
                        .font(.system(size: platformValue(watch: 12, ios: 14), weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, platformValue(watch: 8, ios: 12))
                        .background(Color.yellow.gradient)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, platformValue(watch: 10, ios: 20))
        }
    }
    
    private func platformValue<T>(watch: T, ios: T) -> T {
        #if os(watchOS)
        return watch
        #else
        return ios
        #endif
    }
}

struct ScoreboardRow: View {
    let label: String
    let results: [Int]
    let opponentResults: [Int]
    let isMatchWinner: Bool
    let isGrandSlam: Bool
    
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
                    .font(.system(size: platformValue(watch: 9, ios: 11), weight: .black, design: .rounded))
                    .foregroundColor(isMatchWinner ? .white : .white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.leading, 8)
            .frame(width: platformValue(watch: 55, ios: 80), alignment: .leading)
            
            // Results
            HStack(spacing: platformValue(watch: 4, ios: 12)) {
                let maxSets = isGrandSlam ? 5 : 3
                ForEach(0..<max(maxSets, results.count), id: \.self) { index in
                    let score = index < results.count ? results[index] : -1
                    let opponentScore = index < opponentResults.count ? opponentResults[index] : -1
                    
                    Text(score >= 0 ? "\(score)" : "–")
                        .font(.system(size: platformValue(watch: 14, ios: 24), weight: .black, design: .monospaced))
                        .foregroundColor(score >= 0 ? (score > opponentScore ? .yellow : .white) : .white.opacity(0.15))
                        .frame(width: platformValue(watch: 14, ios: 25))
                }
            }
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: platformValue(watch: 35, ios: 60))
    }
    
    private func platformValue<T>(watch: T, ios: T) -> T {
        #if os(watchOS)
        return watch
        #else
        return ios
        #endif
    }
}

#Preview {
    MatchSummaryView(state: MatchState(
        team1Sets: 3,
        team2Sets: 1,
        scoringSystem: .standard,
        useTieBreak: true,
        isGrandSlam: true,
        completedSets: [
            SetResult(team1Games: 6, team2Games: 4),
            SetResult(team1Games: 4, team2Games: 6),
            SetResult(team1Games: 7, team2Games: 5),
            SetResult(team1Games: 6, team2Games: 2)
        ]
    ), onUndo: {}, onDismiss: {})
}

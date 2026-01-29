import SwiftUI
import PadelCore

struct MatchSummaryView: View {
    let state: MatchState
    let onUndo: () -> Void
    let onDismiss: () -> Void
    
    var winner: Int {
        if state.team1Sets > state.team2Sets { return 1 }
        if state.team2Sets > state.team1Sets { return 2 }
        return 0 // Tie
    }
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.black.ignoresSafeArea()
            
            // Subtle Gradient Accent
            RadialGradient(
                colors: [winner == 1 ? .green.opacity(0.12) : (winner == 2 ? .blue.opacity(0.12) : .yellow.opacity(0.12)), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 500
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
                Text("MATCH RESULT")
                    .font(.system(size: platformValue(watch: 10, ios: 12), weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Image(systemName: "circle.fill")
                    .font(.system(size: 4))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, platformValue(watch: 5, ios: 30))
            .padding(.bottom, 12)
            
            // Winner Announcement (iOS only)
            #if !os(watchOS)
            VStack(spacing: 4) {
                Text(winner != 0 ? "GAME SET MATCH" : "MATCH OVER")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(winner != 0 ? "TEAM \(winner) SECURES THE WIN" : "IT'S A DRAW")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                    .foregroundColor(.zinc400)
            }
            .padding(.bottom, 40)
            #endif
            
            // Compact Scoreboard (Glassmorphism)
            VStack(spacing: 0) {
                ScoreboardRow(
                    label: state.team1.isEmpty ? "TEAM 1" : state.team1.uppercased(),
                    results: state.completedSets.map { $0.team1Games },
                    opponentResults: state.completedSets.map { $0.team2Games },
                    isMatchWinner: winner == 1,
                    isGrandSlam: state.isGrandSlam
                )
                
                Divider()
                    .background(Color.white.opacity(0.05))
                
                ScoreboardRow(
                    label: state.team2.isEmpty ? "TEAM 2" : state.team2.uppercased(),
                    results: state.completedSets.map { $0.team2Games },
                    opponentResults: state.completedSets.map { $0.team1Games },
                    isMatchWinner: winner == 2,
                    isGrandSlam: state.isGrandSlam
                )
            }
            .background(
                RoundedRectangle(cornerRadius: platformValue(watch: 12, ios: 24))
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: platformValue(watch: 12, ios: 24))
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 8)
            
            Spacer(minLength: platformValue(watch: 10, ios: 40))
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onUndo) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("UNDO")
                            .font(.system(size: 10, weight: .black))
                    }
                    .font(.system(size: platformValue(watch: 12, ios: 14), weight: .black, design: .rounded))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, platformValue(watch: 8, ios: 18))
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: onDismiss) {
                    Text("DONE")
                        .font(.system(size: platformValue(watch: 12, ios: 14), weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, platformValue(watch: 8, ios: 18))
                        .background(Color.yellow.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .yellow.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, platformValue(watch: 10, ios: 40))
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
                    .foregroundColor(isMatchWinner ? .white : .white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.leading, 12)
            .frame(width: platformValue(watch: 55, ios: 120), alignment: .leading)
            
            // Results
            HStack(spacing: platformValue(watch: 4, ios: 16)) {
                let maxSets = isGrandSlam ? 5 : 3
                ForEach(0..<max(maxSets, results.count), id: \.self) { index in
                    let score = index < results.count ? results[index] : -1
                    let opponentScore = index < opponentResults.count ? opponentResults[index] : -1
                    
                    Text(score >= 0 ? "\(score)" : "–")
                        .font(.system(size: platformValue(watch: 14, ios: 32), weight: .black, design: .monospaced))
                        .foregroundColor(score >= 0 ? (score > opponentScore ? .yellow : .white) : .white.opacity(0.05))
                        .frame(width: platformValue(watch: 14, ios: 30))
                }
            }
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: platformValue(watch: 35, ios: 80))
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
        ],
        team1: "Galán/Lebrón",
        team2: "Coello/Tapia"
    ), onUndo: {}, onDismiss: {})
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

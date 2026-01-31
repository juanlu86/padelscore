import Foundation
import FirebaseFirestore
import PadelCore

#if !os(watchOS)
public enum MatchFirestoreMapper {
    public static func mapToFirestore(state: MatchState) -> [String: Any] {
        return [
            "team1": state.team1.isEmpty ? "Team 1" : state.team1,
            "team2": state.team2.isEmpty ? "Team 2" : state.team2,
            "score": [
                "team1": state.isTieBreak ? "\(state.team1TieBreakPoints)" : state.team1Score.rawValue,
                "team2": state.isTieBreak ? "\(state.team2TieBreakPoints)" : state.team2Score.rawValue
            ],
            "games": [
                "team1": state.team1Games,
                "team2": state.team2Games
            ],
            "sets": [
                "team1": state.team1Sets,
                "team2": state.team2Sets
            ],
            "completedSets": state.completedSets.map { [
                "team1": $0.team1Games,
                "team2": $0.team2Games
            ]},
            "servingTeam": state.servingTeam,
            "status": state.isMatchOver ? "finished" : "live",
            "scoringSystem": state.scoringSystem.rawValue,
            "deuceCount": state.deuceCount,
            "version": state.version,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
}
#endif

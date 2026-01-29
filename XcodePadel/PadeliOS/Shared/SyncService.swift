import Foundation
#if !os(watchOS)
import FirebaseFirestore
#endif
import PadelCore

#if !os(watchOS)
public class SyncService {
    public static let shared = SyncService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Syncs the match state to Firestore in a background task
    public func syncMatch(state: MatchState) {
        // Run in a detached task to ensure it's truly off the main actor
        Task.detached(priority: .background) {
            let data = SyncService.mapToFirestore(state: state)
            
            do {
                try await self.db.collection("matches").document("test-match").setData(data, merge: true)
                print("✅ Match synced to Firestore")
            } catch {
                print("❌ Sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Maps MatchState to Firestore dictionary (Internal for testing)
    public static func mapToFirestore(state: MatchState) -> [String: Any] {
        return [
            "team1": "Team 1",
            "team2": "Team 2",
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
            "status": state.isMatchOver ? "finished" : "live",
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
}
#endif

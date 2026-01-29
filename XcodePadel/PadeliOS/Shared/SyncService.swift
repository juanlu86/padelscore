import Foundation
#if !os(watchOS)
import FirebaseFirestore
#endif
import PadelCore

#if !os(watchOS)
import FirebaseFirestore
#endif
import PadelCore
import Combine

#if !os(watchOS)
/// Protocol to allow mocking Firestore for tests
public protocol FirestoreSyncable {
    func setData(_ data: [String: Any], forDocument path: String) async throws
}

/// Production implementation of Firestore sync
public class ProductionFirestore: FirestoreSyncable {
    private let db = Firestore.firestore()
    public init() {}
    public func setData(_ data: [String: Any], forDocument path: String) async throws {
        try await db.collection("matches").document(path).setData(data, merge: true)
    }
}

public class SyncService: ObservableObject {
    public enum Status: Equatable {
        case idle
        case syncing
        case synced
        case failed(String)
    }
    
    @Published public var status: Status = .idle
    public static let shared = SyncService()
    
    private let syncProvider: FirestoreSyncable
    
    /// Initializer with dependency injection
    public init(provider: FirestoreSyncable = ProductionFirestore()) {
        self.syncProvider = provider
    }
    
    /// Syncs the match state to Firestore
    public func syncMatch(state: MatchState) {
        self.status = .syncing
        
        Task { @MainActor in
            let data = SyncService.mapToFirestore(state: state)
            
            do {
                try await self.syncProvider.setData(data, forDocument: "test-match")
                self.status = .synced
                print("✅ Match synced to Firestore")
            } catch {
                self.status = .failed(error.localizedDescription)
                print("❌ Sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Maps MatchState to Firestore dictionary
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
            "completedSets": state.completedSets.map { [
                "team1": $0.team1Games,
                "team2": $0.team2Games
            ]},
            "servingTeam": state.servingTeam,
            "status": state.isMatchOver ? "finished" : "live",
            "scoringSystem": state.scoringSystem.rawValue,
            "deuceCount": state.deuceCount,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
}
#endif

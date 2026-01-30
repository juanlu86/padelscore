import Foundation
import Combine
import PadelCore

#if !os(watchOS)
import FirebaseFirestore

/// Protocol to allow mocking Firestore for tests
public protocol FirestoreSyncable {
    func setData(_ data: [String: Any], collection: String, document: String) async throws
}

/// Production implementation of Firestore sync
public class ProductionFirestore: FirestoreSyncable {
    public init() {}
    public func setData(_ data: [String: Any], collection: String, document: String) async throws {
        // Fetch Firestore instance lazily to ensure it uses settings applied in AppDelegate/App
        try await Firestore.firestore().collection(collection).document(document).setData(data, merge: true)
    }
}

@MainActor
public class SyncService: ObservableObject, SyncProvider {
    public var statusPublisher: AnyPublisher<Status, Never> {
        $status.eraseToAnyPublisher()
    }
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
    
    private var pendingUpdate: (MatchState, String?)?
    
    /// Syncs the match state to Firestore
    public func syncMatch(state: MatchState, courtId: String?) {
        // If we are already syncing, queue this update as the "latest intent"
        if status == .syncing {
            print("⏳ Sync in progress. Queuing update for v\(state.version)")
            pendingUpdate = (state, courtId)
            return
        }
        
        performSync(state: state, courtId: courtId)
    }
    
    private func performSync(state: MatchState, courtId: String?) {
        status = .syncing
        
        Task {
            let data = SyncService.mapToFirestore(state: state)
            let path = courtId != nil ? "courts/\(courtId!)" : "matches/test-match"
            
            do {
                if let courtId = courtId {
                    // Sync to a specific court's liveMatch field
                    try await self.syncProvider.setData(["liveMatch": data], collection: "courts", document: courtId)
                } else {
                    // Legacy sync for testing
                    try await self.syncProvider.setData(data, collection: "matches", document: "test-match")
                }
                print("✅ Match synced to \(path)")
                
                // Sync finished successfully. Check if there's a pending update.
                self.processPendingUpdate()
                
            } catch {
                self.status = .failed(error.localizedDescription)
                print("❌ Sync error: \(error.localizedDescription)")
                
                // Even on error, we should probably try to sync the latest pending state
                // to eventually reach consistency.
                self.processPendingUpdate()
            }
        }
    }
    
    private func processPendingUpdate() {
        if let pending = pendingUpdate {
            print("🔄 Found pending update (v\(pending.0.version)). Triggering next sync.")
            let (state, courtId) = pending
            pendingUpdate = nil
            // Recursively call performSync (not syncMatch, to avoid re-queuing logic if we want to force start)
            // But actually performSync sets status=.syncing immediately, so it's fine.
            performSync(state: state, courtId: courtId)
        } else {
            status = .synced
        }
    }
    
    /// Syncs the match state to Firestore (Async variant)
    public func syncMatchAsync(state: MatchState, courtId: String?) async throws {
        let data = SyncService.mapToFirestore(state: state)
        // Manual status update for UI feedback
        status = .syncing
        
        do {
            if let courtId = courtId {
                try await self.syncProvider.setData(["liveMatch": data], collection: "courts", document: courtId)
                print("✅ [Async] Match synced to courts/\(courtId)")
            } else {
                try await self.syncProvider.setData(data, collection: "matches", document: "test-match")
            }
            status = .synced
        } catch {
            status = .failed(error.localizedDescription)
            print("❌ [Async] Sync error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Unlinks the match from the court in Firestore (clears liveMatch)
    /// Unlinks the match from the court in Firestore (clears liveMatch)
    public func unlinkMatch(courtId: String) async {
        let collection = "courts"
        let document = courtId
        
        do {
            // Use FieldValue.delete() to remove the field
            try await self.syncProvider.setData(["liveMatch": FieldValue.delete()], collection: collection, document: document)
            print("✅ Unlinked match from court \(courtId)")
        } catch {
            print("❌ Failed to unlink match: \(error.localizedDescription)")
        }
    }
    
    /// Maps MatchState to Firestore dictionary
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

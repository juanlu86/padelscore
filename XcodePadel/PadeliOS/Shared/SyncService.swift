import Foundation
import Combine
import PadelCore

#if !os(watchOS)
import FirebaseFirestore

/// Protocol to allow mocking Firestore for tests
@MainActor
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
    public init(provider: FirestoreSyncable? = nil) {
        self.syncProvider = provider ?? ProductionFirestore()
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
            let data = MatchFirestoreMapper.mapToFirestore(state: state)
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
                self.processPendingUpdate(latestStatus: .synced)
                
            } catch {
                self.status = .failed(error.localizedDescription)
                print("❌ Sync error: \(error.localizedDescription)")
                
                // Even on error, we should probably try to sync the latest pending state
                // to eventually reach consistency.
                self.processPendingUpdate(latestStatus: .failed(error.localizedDescription))
            }
        }
    }
    
    private func processPendingUpdate(latestStatus: Status) {
        if let pending = pendingUpdate {
            print("🔄 Found pending update (v\(pending.0.version)). Triggering next sync.")
            let (state, courtId) = pending
            pendingUpdate = nil
            // Recursively call performSync (not syncMatch, to avoid re-queuing logic if we want to force start)
            // But actually performSync sets status=.syncing immediately, so it's fine.
            performSync(state: state, courtId: courtId)
        } else {
            status = latestStatus
        }
    }
    
    /// Syncs the match state to Firestore (Async variant)
    public func syncMatchAsync(state: MatchState, courtId: String?) async throws {
        let data = MatchFirestoreMapper.mapToFirestore(state: state)
        // Manual status update for UI feedback
        status = .syncing
        
        do {
            if let courtId = courtId {
                try await self.syncProvider.setData(["liveMatch": data], collection: "courts", document: courtId)
                print("✅ [Async] Match synced to courts/\(courtId)")
            } else {
                try await self.syncProvider.setData(data, collection: "matches", document: "test-match")
            }
            // Sync finished successfully. Check if there's a pending update.
            self.processPendingUpdate(latestStatus: .synced)
        } catch {
            self.status = .failed(error.localizedDescription)
            print("❌ [Async] Sync error: \(error.localizedDescription)")
            
            // Check for pending updates even on failure to ensure eventual consistency
            self.processPendingUpdate(latestStatus: .failed(error.localizedDescription))
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
}

#endif

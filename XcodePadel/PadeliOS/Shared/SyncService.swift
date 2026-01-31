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
@Observable
public class SyncService: SyncProvider {
    public enum Status: Equatable {
        case idle
        case syncing
        case synced
        case failed(SyncError)
    }
    
    public enum SyncError: Error, Equatable {
        case networkError(String)
        case dataError(String)
        case unauthorized
        case unknown(String)
        
        public var localizedDescription: String {
            switch self {
            case .networkError(let msg): return "Network: \(msg)"
            case .dataError(let msg): return "Data: \(msg)"
            case .unauthorized: return "Unauthorized"
            case .unknown(let msg): return msg
            }
        }
    }

    public var status: Status {
        get { _observedStatus }
        set {
            _observedStatus = newValue
            statusSubject.send(newValue)
        }
    }

    private var _observedStatus: Status = .idle
    private let statusSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public var statusPublisher: AnyPublisher<Status, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    public static let shared = SyncService()
    
    private let syncProvider: FirestoreSyncable
    private var pendingUpdate: (MatchState, String?)?
    
    public init(provider: FirestoreSyncable? = nil) {
        self.syncProvider = provider ?? ProductionFirestore()
    }
    
    public func syncMatch(state: MatchState, courtId: String?) {
        if status == .syncing {
            pendingUpdate = (state, courtId)
            return
        }
        performSync(state: state, courtId: courtId)
    }
    
    private func performSync(state: MatchState, courtId: String?) {
        status = .syncing
        
        Task {
            let data = MatchFirestoreMapper.mapToFirestore(state: state)
            
            do {
                if let courtId = courtId {
                    try await self.syncProvider.setData(["liveMatch": data], collection: "courts", document: courtId)
                } else {
                    try await self.syncProvider.setData(data, collection: "matches", document: "test-match")
                }
                print("✅ Match synced (v\(state.version))")
                self.processPendingUpdate(latestStatus: .synced)
            } catch {
                let syncErr = SyncError.networkError(error.localizedDescription)
                self.status = .failed(syncErr)
                print("❌ Sync error: \(syncErr.localizedDescription)")
                self.processPendingUpdate(latestStatus: .failed(syncErr))
            }
        }
    }
    
    private func processPendingUpdate(latestStatus: Status) {
        if let pending = pendingUpdate {
            let (state, courtId) = pending
            pendingUpdate = nil
            performSync(state: state, courtId: courtId)
        } else {
            status = latestStatus
        }
    }
    
    public func syncMatchAsync(state: MatchState, courtId: String?) async throws {
        let data = MatchFirestoreMapper.mapToFirestore(state: state)
        status = .syncing
        
        do {
            if let courtId = courtId {
                try await self.syncProvider.setData(["liveMatch": data], collection: "courts", document: courtId)
            } else {
                try await self.syncProvider.setData(data, collection: "matches", document: "test-match")
            }
            self.processPendingUpdate(latestStatus: .synced)
        } catch {
            let syncErr = SyncError.networkError(error.localizedDescription)
            self.status = .failed(syncErr)
            self.processPendingUpdate(latestStatus: .failed(syncErr))
            throw error
        }
    }
    
    public func unlinkMatch(courtId: String) async {
        do {
            try await self.syncProvider.setData(["liveMatch": FieldValue.delete()], collection: "courts", document: courtId)
            print("✅ Unlinked match from court \(courtId)")
        } catch {
            print("❌ Failed to unlink match: \(error.localizedDescription)")
        }
    }
}
#endif

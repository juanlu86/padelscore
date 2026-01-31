import XCTest
#if !os(watchOS)
import PadelCore
import FirebaseFirestore
@testable import PadeliOS

final class MockFirestore: FirestoreSyncable {
    var shouldFail = false
    var lastData: [String: Any]?
    
    var lastCollection: String?
    var lastDocument: String?
    
    var writeCount = 0
    
    func setData(_ data: [String: Any], collection: String, document: String) async throws {
        writeCount += 1
        if shouldFail {
            throw NSError(domain: "SyncError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network unreachable"])
        }
        lastData = data
        lastCollection = collection
        lastDocument = document
    }
}

@MainActor
final class SyncServiceTests: XCTestCase {
    
    func testMapToFirestoreCorrectlyMapsNormalScore() {
        var state = MatchState()
        state.team1Score = .thirty
        state.team2Score = .fifteen
        state.team1Games = 2
        state.team2Games = 1
        state.isMatchOver = false
        
        let data = MatchFirestoreMapper.mapToFirestore(state: state)
        
        XCTAssertEqual(data["status"] as? String, "live")
        
        let score = data["score"] as? [String: String]
        XCTAssertEqual(score?["team1"], "30")
        XCTAssertEqual(score?["team2"], "15")
        
        let games = data["games"] as? [String: Int]
        XCTAssertEqual(games?["team1"], 2)
        XCTAssertEqual(games?["team2"], 1)
        
        XCTAssertEqual(data["version"] as? Int, state.version)
        XCTAssertEqual(data["scoringSystem"] as? String, state.scoringSystem.rawValue)
        XCTAssertEqual(data["deuceCount"] as? Int, state.deuceCount)
        
        XCTAssertNotNil(data["updatedAt"])
    }
    
    func testSyncSuccessUpdatesStatusToSynced() async {
        let mock = MockFirestore()
        let service = SyncService(provider: mock)
        let state = MatchState()
        
        service.syncMatch(state: state, courtId: nil)
        
        // Since syncMatch uses Task { @MainActor in ... }, we should be able to check 
        // the status after a small delay or by using a continuation.
        // For simplicity in this test, we'll just wait a bit.
        // Since syncMatch uses debouncing (0.5s), we must wait at least that long.
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
        
        let status = service.status
        XCTAssertEqual(status, .synced)
        XCTAssertNotNil(mock.lastData)
    }
    
    func testSyncFailureUpdatesStatusToFailed() async {
        let mock = MockFirestore()
        mock.shouldFail = true
        let service = SyncService(provider: mock)
        let state = MatchState()
        
        service.syncMatch(state: state, courtId: nil)
        
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        // Wait and check
        if case .failed(_) = service.status {
            // success
        } else {
             try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        let status = service.status
        if case .failed(let error) = status {
            XCTAssertEqual(error.localizedDescription, "Network: Network unreachable")
        } else {
            XCTFail("Status should be failed, but was \(status)")
        }
    }
    
    func testSyncMatchWithCourtIdTargetsCourtsCollection() async {
        let mock = MockFirestore()
        let service = SyncService(provider: mock)
        let state = MatchState()
        let courtId = "test-court-123"
        
        service.syncMatch(state: state, courtId: courtId)
        
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        XCTAssertEqual(mock.lastCollection, "courts")
        XCTAssertEqual(mock.lastDocument, courtId)
        XCTAssertNotNil(mock.lastData?["liveMatch"])
    }
    
    func testRapidUpdatesAreDebounced() async {
        let mock = MockFirestore()
        // Provide the mock explicitly
        let service = SyncService(provider: mock)
        
        // 1. Trigger rapid updates
        for i in 1...5 {
            var state = MatchState()
            state.version = i
            // We expect syncMatch to define the debounce logic internally
            service.syncMatch(state: state, courtId: nil)
            // No sleep, simulate instant successive calls
        }
        
        // 2. Wait for debounce interval (assuming ~0.5s in implementation)
        // We wait slightly longer to be safe
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
        
        // 3. Verify ONLY the last write happened
        // If NO throttling exists, this will be 5.
        // If throttling works, this should be 1.
        XCTAssertEqual(mock.writeCount, 1, "Should have collapsed 5 updates into 1 write")
        XCTAssertEqual(mock.lastData?["version"] as? Int, 5, "Should have synced the latest version")
    }
}
#endif

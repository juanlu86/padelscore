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
    
    func setData(_ data: [String: Any], collection: String, document: String) async throws {
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
        
        let data = SyncService.mapToFirestore(state: state)
        
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
        
        // Use an expectation to wait for the @MainActor task
        let expectation = XCTestExpectation(description: "Sync finishes")
        
        await service.syncMatch(state: state, courtId: nil)
        
        // Since syncMatch uses Task { @MainActor in ... }, we should be able to check 
        // the status after a small delay or by using a continuation.
        // For simplicity in this test, we'll just wait a bit.
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
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
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Wait and check
        if case .failed(_) = service.status {
            // success
        } else {
             try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        let status = service.status
        if case .failed(let message) = status {
            XCTAssertEqual(message, "Network unreachable")
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
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(mock.lastCollection, "courts")
        XCTAssertEqual(mock.lastDocument, courtId)
        XCTAssertNotNil(mock.lastData?["liveMatch"])
    }
}
#endif

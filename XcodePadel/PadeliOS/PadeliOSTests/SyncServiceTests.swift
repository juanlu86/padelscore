import XCTest
#if !os(watchOS)
import PadelCore
import FirebaseFirestore
@testable import PadeliOS

final class MockFirestore: FirestoreSyncable {
    var shouldFail = false
    var lastData: [String: Any]?
    
    func setData(_ data: [String: Any], forDocument path: String) async throws {
        if shouldFail {
            throw NSError(domain: "SyncError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network unreachable"])
        }
        lastData = data
    }
}

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
        
        XCTAssertNotNil(data["updatedAt"])
    }
    
    func testSyncSuccessUpdatesStatusToSynced() async {
        let mock = MockFirestore()
        let service = SyncService(provider: mock)
        let state = MatchState()
        
        // Use an expectation to wait for the @MainActor task
        let expectation = XCTestExpectation(description: "Sync finishes")
        
        service.syncMatch(state: state)
        
        // Since syncMatch uses Task { @MainActor in ... }, we should be able to check 
        // the status after a small delay or by using a continuation.
        // For simplicity in this test, we'll just wait a bit.
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        XCTAssertEqual(service.status, .synced)
        XCTAssertNotNil(mock.lastData)
    }
    
    func testSyncFailureUpdatesStatusToFailed() async {
        let mock = MockFirestore()
        mock.shouldFail = true
        let service = SyncService(provider: mock)
        let state = MatchState()
        
        service.syncMatch(state: state)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        if case .failed(let message) = service.status {
            XCTAssertEqual(message, "Network unreachable")
        } else {
            XCTFail("Status should be failed, but was \(service.status)")
        }
    }
}
#endif

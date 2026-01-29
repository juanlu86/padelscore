import XCTest
#if !os(watchOS)
import PadelCore
import FirebaseFirestore
@testable import PadeliOS

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
    
    func testMapToFirestoreCorrectlyMapsTieBreakScore() {
        var state = MatchState()
        state.isTieBreak = true
        state.team1TieBreakPoints = 5
        state.team2TieBreakPoints = 3
        
        let data = SyncService.mapToFirestore(state: state)
        
        let score = data["score"] as? [String: String]
        XCTAssertEqual(score?["team1"], "5")
        XCTAssertEqual(score?["team2"], "3")
    }
    
    func testMapToFirestoreCorrectlyMapsMatchOver() {
        var state = MatchState()
        state.isMatchOver = true
        
        let data = SyncService.mapToFirestore(state: state)
        
        XCTAssertEqual(data["status"] as? String, "finished")
    }
}
#endif

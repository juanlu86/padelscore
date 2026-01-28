import XCTest
@testable import PadelCore

final class PadelLogicTests: XCTestCase {
    var logic: PadelLogic!
    
    override func setUp() {
        super.setUp()
        logic = PadelLogic()
    }
    
    func testSimplePoints() {
        var state = MatchState()
        
        // 0 -> 15
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .fifteen)
        XCTAssertEqual(state.team2Score, .zero)
        
        // 15 -> 30
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .thirty)
        
        // 30 -> 40
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .forty)
    }
    
    func testWinGame() {
        var state = MatchState(team1Score: .forty, team2Score: .thirty)
        
        // 40 -> Game
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Games, 1)
        XCTAssertEqual(state.team1Score, .zero)
        XCTAssertEqual(state.team2Score, .zero)
    }
    
    func testDeuceToAdvantage() {
        var state = MatchState(team1Score: .forty, team2Score: .forty)
        
        // Deuce -> Ad
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .advantage)
        XCTAssertEqual(state.team2Score, .forty)
        
        // Ad -> Game
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Games, 1)
        XCTAssertEqual(state.team2Games, 0)
    }
    
    func testBackToDeuce() {
        var state = MatchState(team1Score: .forty, team2Score: .advantage)
        
        // Ad (them) -> Deuce
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .forty)
        XCTAssertEqual(state.team2Score, .forty)
    }
}

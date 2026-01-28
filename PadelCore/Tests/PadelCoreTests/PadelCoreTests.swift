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
        var state = MatchState(team1Score: .forty, team1Games: 0)
        
        // 40 -> Win Game (1-0)
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Games, 1)
        XCTAssertEqual(state.team1Score, .zero)
        XCTAssertEqual(state.team2Score, .zero)
    }
    
    func testWinSetNormal() {
        // 5-0 in games, 40-0 in points
        var state = MatchState(team1Score: .forty, team1Games: 5, team2Games: 0)
        
        // Win Game -> Win Set (6-0)
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertEqual(state.team1Games, 0) // Reset for next set
        XCTAssertEqual(state.completedSets.count, 1)
        XCTAssertEqual(state.completedSets[0].team1Games, 6)
        XCTAssertEqual(state.completedSets[0].team2Games, 0)
    }
    
    func testNoSetWinAt6_5() {
        // 5-5 in games, 40-0 in points
        var state = MatchState(team1Score: .forty, team1Games: 5, team2Games: 5)
        
        // Win Game -> 6-5 (No set win yet, need 2 game lead or tie-break)
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Sets, 0)
        XCTAssertEqual(state.team1Games, 6)
        XCTAssertEqual(state.team2Games, 5)
    }
    
    func testSetWinAt7_5() {
        // 6-5 in games, 40-0 in points
        var state = MatchState(team1Score: .forty, team1Games: 6, team2Games: 5)
        
        // Win Game -> 7-5 (Set win)
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertEqual(state.completedSets[0].team1Games, 7)
    }
    
    func testTieBreakTrigger() {
        // 5-6 in games, 40-0 for Team 1
        var state = MatchState(team1Score: .forty, team1Games: 5, team2Games: 6)
        
        // Team 1 wins game -> 6-6 -> Tie-break
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Games, 6)
        XCTAssertEqual(state.team2Games, 6)
        XCTAssertTrue(state.isTieBreak)
    }
    
    func testTieBreakWin() {
        // Tie break at 6-5 points
        var state = MatchState(team1Games: 6, team2Games: 6, team1TieBreakPoints: 6, team2TieBreakPoints: 5, isTieBreak: true)
        
        // Score point -> 7-5 win tie-break -> 7-6 set win
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Sets, 1)
        XCTAssertEqual(state.completedSets[0].team1Games, 7)
        XCTAssertEqual(state.completedSets[0].team2Games, 6)
        XCTAssertFalse(state.isTieBreak)
    }
    
    func testMatchWin() {
        // 1 set to 0, 5-0 in games, 40-0 in points
        var state = MatchState(team1Score: .forty, team1Games: 5, team1Sets: 1)
        
        // Win Set -> Win Match
        state = logic.scorePoint(forTeam1: true, currentState: state)
        
        XCTAssertEqual(state.team1Sets, 2)
        XCTAssertTrue(state.isMatchOver)
    }
    
    func testGoldenPoint() {
        var state = MatchState(team1Score: .forty, team2Score: .forty)
        state.scoringSystem = .goldenPoint
        
        // Winner of point wins game immediately
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Games, 1)
        XCTAssertEqual(state.team1Score, .zero)
    }
    
    func testStarPointSuddenDeathAt3rdDeuce() {
        var state = MatchState()
        state.scoringSystem = .starPoint
        
        // 1. Reach 1st Deuce (40-40) from 30-40
        state.team1Score = .thirty
        state.team2Score = .forty
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.deuceCount, 1)
        XCTAssertEqual(state.team1Score, .forty)
        
        // 2. Play point from 1st deuce -> Advantage
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .advantage)
        XCTAssertEqual(state.deuceCount, 1)
        
        // 3. Return to 2nd deuce
        state = logic.scorePoint(forTeam1: false, currentState: state)
        XCTAssertEqual(state.deuceCount, 2)
        XCTAssertEqual(state.team1Score, .forty)
        
        // 4. Play point from 2nd deuce -> Advantage
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Score, .advantage)
        
        // 5. Return to 3rd deuce
        state = logic.scorePoint(forTeam1: false, currentState: state)
        XCTAssertEqual(state.deuceCount, 3)
        XCTAssertEqual(state.team1Score, .forty)
        
        // NOW: 3rd deuce is active. The NEXT point must be sudden death!
        state = logic.scorePoint(forTeam1: true, currentState: state)
        XCTAssertEqual(state.team1Games, 1)
        XCTAssertEqual(state.team1Score, .zero) // Game won
    }
}

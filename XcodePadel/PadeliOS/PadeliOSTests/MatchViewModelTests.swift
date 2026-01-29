import XCTest
import Combine
import PadelCore
@testable import PadeliOS

final class MatchViewModelTests: XCTestCase {
    var viewModel: MatchViewModel!
    var mockConnectivity: MockConnectivityProvider!
    var mockSync: MockSyncProvider!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockConnectivity = MockConnectivityProvider()
        mockSync = MockSyncProvider()
        viewModel = MatchViewModel(connectivity: mockConnectivity, sync: mockSync)
        cancellables = []
    }

    func testScoreFormatting() {
        viewModel.state.team1Score = .fifteen
        viewModel.state.team2Score = .thirty
        
        XCTAssertEqual(viewModel.team1DisplayScore, "15")
        XCTAssertEqual(viewModel.team2DisplayScore, "30")
        
        viewModel.state.isTieBreak = true
        viewModel.state.team1TieBreakPoints = 5
        viewModel.state.team2TieBreakPoints = 7
        
        XCTAssertEqual(viewModel.team1DisplayScore, "5")
        XCTAssertEqual(viewModel.team2DisplayScore, "7")
    }

    func testSpecialPointLabel() {
        viewModel.state.scoringSystem = .goldenPoint
        viewModel.state.team1Score = .forty
        viewModel.state.team2Score = .forty
        
        XCTAssertEqual(viewModel.specialPointLabel, "GOLDEN POINT")
        
        viewModel.state.scoringSystem = .starPoint
        viewModel.state.deuceCount = 2
        XCTAssertNil(viewModel.specialPointLabel)
        
        viewModel.state.deuceCount = 3
        XCTAssertEqual(viewModel.specialPointLabel, "STAR POINT")
    }

    func testScorePointTriggersSyncAndConnectivity() {
        viewModel.scorePoint(forTeam1: true)
        
        XCTAssertEqual(mockSync.syncCount, 1)
        XCTAssertEqual(mockConnectivity.sendCount, 1)
        XCTAssertEqual(mockSync.lastSyncedState?.team1Score, .fifteen)
        XCTAssertEqual(mockConnectivity.lastSentState?.team1Score, .fifteen)
    }

    func testUndoPointIncrementsVersion() {
        let originalVersion = viewModel.state.version
        viewModel.scorePoint(forTeam1: true)
        let versionAfterPoint = viewModel.state.version
        
        viewModel.undoPoint()
        
        XCTAssertGreaterThan(viewModel.state.version, versionAfterPoint)
        XCTAssertGreaterThan(viewModel.state.version, originalVersion)
    }

    func testResetMatchPreservesSettings() {
        viewModel.state.isGrandSlam = true
        viewModel.state.scoringSystem = .goldenPoint
        
        viewModel.resetMatch()
        
        XCTAssertTrue(viewModel.state.isGrandSlam)
        XCTAssertEqual(viewModel.state.scoringSystem, .goldenPoint)
        XCTAssertEqual(viewModel.state.team1Sets, 0)
    }

    func testUpdateTeamNamesIncrementsVersionAndSyncs() {
        let originalVersion = viewModel.state.version
        
        viewModel.updateTeamNames(team1: "Galán/Lebrón", team2: "Coello/Tapia")
        
        XCTAssertEqual(viewModel.state.team1, "Galán/Lebrón")
        XCTAssertEqual(viewModel.state.team2, "Coello/Tapia")
        XCTAssertGreaterThan(viewModel.state.version, originalVersion)
        XCTAssertEqual(mockSync.syncCount, 1)
        XCTAssertEqual(mockConnectivity.sendCount, 1)
    }
}

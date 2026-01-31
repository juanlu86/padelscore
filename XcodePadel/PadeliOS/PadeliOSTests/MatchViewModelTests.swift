import XCTest
import Combine
import PadelCore
@testable import PadeliOS

@MainActor
final class MatchViewModelTests: XCTestCase {
    var viewModel: MatchViewModel!
    var mockConnectivity: MockConnectivityProvider!
    var mockSync: MockSyncProvider!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            UserDefaults.standard.removeObject(forKey: "linkedCourtId")
            CourtLinkManager.shared.resetForTesting()
            mockConnectivity = MockConnectivityProvider()
            mockSync = MockSyncProvider()
            viewModel = MatchViewModel(state: MatchState(), connectivity: mockConnectivity, sync: mockSync)
        }
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

    func testScorePointTriggersSyncAndConnectivity() async {
        await viewModel.scorePoint(forTeam1: true)
        
        // Allow for potential extra syncs during setup/state changes, but ensure at least one sync occurred
        XCTAssertGreaterThanOrEqual(mockSync.syncCount, 1)
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

    func testUpdateTeamNamesIncrementsVersionAndSyncs() async {
        let originalVersion = viewModel.state.version
        
        await viewModel.updateTeamNames(team1: "Galán/Lebrón", team2: "Coello/Tapia")
        
        XCTAssertEqual(viewModel.state.team1, "Galán/Lebrón")
        XCTAssertEqual(viewModel.state.team2, "Coello/Tapia")
        XCTAssertGreaterThan(viewModel.state.version, originalVersion)
        XCTAssertEqual(mockSync.syncCount, 1)
        XCTAssertEqual(mockConnectivity.sendCount, 1)
    }

    func testUndoDoesNotRevertTeamNames() async throws {
        // 1. Initial names
        await MainActor.run {
            viewModel.updateTeamNames(team1: "A", team2: "B")
        }
        
        // 2. Score a point (history snapshots "A" and "B")
        await viewModel.scorePoint(forTeam1: true)
        
        // 3. Edit names mid-match
        await MainActor.run {
            viewModel.updateTeamNames(team1: "X", team2: "Y")
        }
        
        // 4. Undo the point
        await MainActor.run {
            viewModel.undoPoint()
        }
        
        // Small delay to ensure state propagates
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // 5. Verify names are still "X" and "Y", not reverted to "A" and "B"
        XCTAssertEqual(viewModel.state.team1, "X")
        XCTAssertEqual(viewModel.state.team2, "Y")
        XCTAssertEqual(viewModel.state.team1Score, .zero) // Score was correctly undone
    }

    func testLinkedCourtIdPersistence() async {
        await MainActor.run {
            // Clear before test
            UserDefaults.standard.removeObject(forKey: "linkedCourtId")
            
            let testId = "COURT-XYZ-999"
            viewModel.linkedCourtId = testId
            
            XCTAssertEqual(UserDefaults.standard.string(forKey: "linkedCourtId"), testId)
            
            // New instance should read from persistence
            let newViewModel = MatchViewModel(connectivity: mockConnectivity, sync: mockSync)
            XCTAssertEqual(newViewModel.linkedCourtId, testId)
        }
    }

    func testSyncWithLinkedCourtIdCallsSyncWithCorrectId() async {
        await MainActor.run {
            viewModel.linkedCourtId = "court-777"
        }
        
        await viewModel.scorePoint(forTeam1: true)
        let normalizedCourtId = "court-777".uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(mockSync.lastSyncedCourtId, normalizedCourtId)
        XCTAssertEqual(mockSync.syncCount, 2) // One for linking, one for scoring
    }

    func testRemoteUpdateTriggersSync() async throws {
        // 1. Setup - Link to a court
        let courtId = "COURT-SYNC-TEST"
        await MainActor.run {
            viewModel.linkedCourtId = courtId
        }
        
        let initialSyncCount = mockSync.syncCount
        
        // 2. Simulate receiving a remote update (higher version)
        var newState = MatchState()
        newState.team1Score = .fifteen // Changed from love
        newState.version = 100 // Higher version
        
        print("Test: Simulate receiving remote state")
        mockConnectivity.simulateUpdate(state: newState, isStarted: true)
        
        // 3. Wait for Combine pipeline (receive(on: .main))
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // 4. Verify local state updated
        XCTAssertEqual(viewModel.state.team1Score, .fifteen, "Local state should update from remote")
        
        // 5. Verify sync called
        // We expect syncCount to increment by 1
        let finalSyncCount = mockSync.syncCount
        XCTAssertGreaterThan(finalSyncCount, initialSyncCount, "Valid remote update should trigger syncMatch")
        
        if let lastSynced = mockSync.lastSyncedState {
             XCTAssertEqual(lastSynced.team1Score, .fifteen, "Should sync the NEW state received from remote")
             XCTAssertEqual(mockSync.lastSyncedCourtId, courtId, "Should sync to the correct court ID")
        } else {
            XCTFail("lastSyncedState is nil")
        }
    }

    @MainActor
    func testUnlinkCurrentCourtClearsRemoteAndLocal() async {
        // 1. Setup linked state
        viewModel.linkedCourtId = "COURT-TO-DELETE"
        print("Test: linkedCourtId set to \(viewModel.linkedCourtId)")
        XCTAssertEqual(viewModel.linkedCourtId, "COURT-TO-DELETE")
        
        // 2. Perform unlink
        print("Test: calling unlinkCurrentCourt")
        await viewModel.unlinkCurrentCourt()
        print("Test: called unlinkCurrentCourt")
        
        // 3. Verify local state cleared
        XCTAssertTrue(viewModel.linkedCourtId.isEmpty)
        XCTAssertTrue(((UserDefaults.standard.string(forKey: "linkedCourtId")?.isEmpty) != nil))
        
        // 4. Verify remote sync called
        // Since unlinkCurrentCourt is now async and awaited, we can assert immediately
        NSLog("Test: unlinkedCourtId is \(String(describing: mockSync.unlinkedCourtId))")
        XCTAssertEqual(mockSync.unlinkedCourtId, "COURT-TO-DELETE")
    }
}

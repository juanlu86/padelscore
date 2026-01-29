import XCTest
import Combine
import PadelCore
@testable import PadeliOS

final class ConnectivitySyncTests: XCTestCase {
    
    var viewModel: MatchViewModel!
    
    override func setUp() {
        super.setUp()
        // Ensure shared state is reset between tests
        ConnectivityService.shared.receivedState = nil
        viewModel = MatchViewModel()
    }
    
    func testStaleVersionIsIgnored() {
        let initialState = MatchState(team1Score: .fifteen, version: 10)
        viewModel.state = initialState
        
        // Simulate receiving an older version
        let staleState = MatchState(team1Score: .forty, version: 9)
        ConnectivityService.shared.receivedState = staleState
        ConnectivityService.shared.receivedIsStarted = true
        
        // MatchViewModel handles the update via Combine, but it should be filtered 
        // by logic if we had filtered it in handleRemoteStateUpdate.
        // Wait for potential debounce/dispatch
        let expectation = XCTestExpectation(description: "Wait for update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // It SHOULD NOT have updated if version is lower
        // Note: ConnectivityService currently doesn't filter, MatchViewModel does the assignment.
        // Wait, ConnectivityService.swift:76 DOES filter! 
        // "if version > lastReceivedVersion { receivedState = state }"
        
        XCTAssertEqual(viewModel.state.team1Score, .fifteen, "State should not have updated with stale version")
    }
    
    func testNewerVersionIsAccepted() {
        let initialState = MatchState(team1Score: .fifteen, version: 10)
        viewModel.state = initialState
        
        // Reset ConnectivityService internal tracker for testing if possible, 
        // but since it's a singleton we rely on the high initial version.
        
        let newState = MatchState(team1Score: .forty, version: 11)
        ConnectivityService.shared.receivedState = newState
        ConnectivityService.shared.receivedIsStarted = true
        
        let expectation = XCTestExpectation(description: "Wait for update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.state.team1Score, .forty, "State should have updated with newer version")
    }
    
    func testRemoteUpdatePopulatesHistory() {
        let initialState = MatchState(team1Score: .fifteen, version: 10)
        viewModel.state = initialState
        
        let newState = MatchState(team1Score: .thirty, version: 11)
        ConnectivityService.shared.receivedState = newState
        ConnectivityService.shared.receivedIsStarted = true
        
        let expectation = XCTestExpectation(description: "Wait for update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify we can undo the remote point
        XCTAssertTrue(viewModel.canUndo, "Remote update should have populated history")
        viewModel.undoPoint()
        XCTAssertEqual(viewModel.state.team1Score, .fifteen, "Undo should revert to the state before the remote update")
    }
    
    func testUndoIncrementsVersion() {
        viewModel.scorePoint(forTeam1: true) // v1
        let versionAfterPoint = viewModel.state.version
        
        viewModel.undoPoint() // should be v2
        XCTAssertGreaterThan(viewModel.state.version, versionAfterPoint, "Undo must strictly increment the version number")
    }
}

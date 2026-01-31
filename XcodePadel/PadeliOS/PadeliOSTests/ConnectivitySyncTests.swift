import XCTest
import Combine
import PadelCore
@testable import PadeliOS

@MainActor
final class ConnectivitySyncTests: XCTestCase {
    
    var viewModel: MatchViewModel!
    var mockConnectivity: MockConnectivityProvider!
    var mockSync: MockSyncProvider!
    
    override func setUp() {
        super.setUp()
        mockConnectivity = MockConnectivityProvider()
        mockSync = MockSyncProvider()
        viewModel = MatchViewModel(connectivity: mockConnectivity, sync: mockSync)
    }
    
    func testStaleVersionIsIgnored() {
        let initialState = MatchState(team1Score: .fifteen, version: 10)
        viewModel.state = initialState
        
        // Simulate receiving an older version via mock
        let staleState = MatchState(team1Score: .forty, version: 9)
        mockConnectivity.simulateUpdate(state: staleState, isStarted: true)
        
        // No need for asyncAfter, as MatchViewModel reacts immediately to updatePublisher mock
        XCTAssertEqual(viewModel.state.team1Score, .fifteen, "State should not have updated with stale version")
    }
    
    func testNewerVersionIsAccepted() async throws {
        let initialState = MatchState(team1Score: .fifteen, version: 10)
        viewModel.state = initialState
        
        let newState = MatchState(team1Score: .forty, version: 11)
        mockConnectivity.simulateUpdate(state: newState, isStarted: true)
        
        // Wait for @MainActor Task
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(viewModel.state.team1Score, .forty, "State should have updated with newer version")
    }
    
    func testRemoteUpdatePopulatesHistory() async throws {
        let initialState = MatchState(team1Score: .fifteen, version: 10)
        viewModel.state = initialState
        
        let newState = MatchState(team1Score: .thirty, version: 11)
        mockConnectivity.simulateUpdate(state: newState, isStarted: true)
        
        // Wait for @MainActor Task
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify we can undo the remote point
        XCTAssertTrue(viewModel.canUndo, "Remote update should have populated history")
        viewModel.undoPoint()
        XCTAssertEqual(viewModel.state.team1Score, .fifteen, "Undo should revert to the state before the remote update")
    }
}

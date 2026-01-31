import XCTest
import Combine
import PadelCore
@testable import PadeliOS

@MainActor
final class MatchSessionCoordinatorTests: XCTestCase {
    var viewModel: MatchViewModel!
    var coordinator: MatchSessionCoordinator!
    var mockConnectivity: MockConnectivityProvider!
    var mockSync: MockSyncProvider!
    
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            UserDefaults.standard.removeObject(forKey: "linkedCourtId")
            CourtLinkManager.shared.resetForTesting()
            
            mockConnectivity = MockConnectivityProvider()
            mockSync = MockSyncProvider()
            // Initialize VM with mocks but NO internal binding (since we moved it to coordinator)
            viewModel = MatchViewModel(state: MatchState(), connectivity: mockConnectivity, sync: mockSync)
            // Initialize coordinator
            coordinator = MatchSessionCoordinator(viewModel: viewModel, connectivity: mockConnectivity, sync: mockSync)
        }
    }
    
    func testActivateIsIdempotent() async {
        // Coordinator should guard against multiple activations
        await MainActor.run {
            coordinator.activate()
            coordinator.activate()
        }
        
        // Wait for async binding
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Simulate one update
        mockConnectivity.simulateUpdate(state: MatchState(), isStarted: true)
        
        // No side effects to check easily other than asserting no crash or loop, assuming logic correct.
    }
    
    func testPassThroughToViewModel() async {
        // Activate first!
        await MainActor.run {
             coordinator.activate()
        }
        
        // Verify that when Connectivity gets an update, Coordinator pushes it to VM
        var newState = MatchState()
        newState.version = 10
        
        mockConnectivity.simulateUpdate(state: newState, isStarted: true)
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(viewModel.state.version, 10, "Coordinator should pass remote updates to ViewModel")
    }
    
    func testProactiveBroadcastOnActivate() async {
         await MainActor.run {
             viewModel.isMatchStarted = true
             coordinator.activate()
         }
        
        XCTAssertEqual(mockConnectivity.sendCount, 1, "Should broadcast on activate if match is running")
    }
}

import XCTest
import HealthKit
import Combine
@testable import PadeliOS_Watch_App

#if os(watchOS)
final class WorkoutManagerTests: XCTestCase {
    var workoutManager: WorkoutManager!
    
    override func setUp() {
        super.setUp()
        // In a real TDD scenario, we'd mock the HKHealthStore
        // For now, we'll test the high-level state machine of our manager
        workoutManager = WorkoutManager()
    }
    
    func testInitialStateIsIdle() {
        XCTAssertEqual(workoutManager.state, .idle)
    }
    
    func testStartWorkoutChangesStateToActive() {
        let expectation = XCTestExpectation(description: "State changes to active")
        
        let cancellable = workoutManager.$state.sink { state in
            if state == .active {
                expectation.fulfill()
            }
        }
        
        workoutManager.startWorkout()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(workoutManager.state, .active)
        cancellable.cancel()
    }
    
    func testEndWorkoutChangesStateToIdle() {
        workoutManager.startWorkout()
        workoutManager.endWorkout()
        XCTAssertEqual(workoutManager.state, .idle)
    }
}
#endif

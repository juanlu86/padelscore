import Foundation
import XCTest
import Combine
import PadelCore
@testable import PadeliOS

public class MockConnectivityProvider: ConnectivityProvider {
    @Published public var receivedState: MatchState?
    @Published public var receivedIsStarted: Bool?
    
    public var receivedStatePublisher: AnyPublisher<MatchState?, Never> {
        $receivedState.eraseToAnyPublisher()
    }
    
    public var receivedIsStartedPublisher: AnyPublisher<Bool?, Never> {
        $receivedIsStarted.eraseToAnyPublisher()
    }
    
    public var lastSentState: MatchState?
    public var lastSentIsStarted: Bool?
    public var sendCount = 0
    
    public func send(state: MatchState, isStarted: Bool) {
        lastSentState = state
        lastSentIsStarted = isStarted
        sendCount += 1
    }
}

public class MockSyncProvider: SyncProvider {
    @Published public var status: SyncService.Status = .idle
    
    public var statusPublisher: AnyPublisher<SyncService.Status, Never> {
        $status.eraseToAnyPublisher()
    }
    
    public var lastSyncedCourtId: String?
    public var lastSyncedState: MatchState?
    public var syncCount = 0
    
    public func syncMatch(state: MatchState, courtId: String? = nil) {
        print("TestMock: syncMatch called for \(String(describing: courtId))")
        lastSyncedState = state
        lastSyncedCourtId = courtId
        syncCount += 1
        status = .synced
    }
    
    public func syncMatchAsync(state: MatchState, courtId: String?) async throws {
        syncMatch(state: state, courtId: courtId)
    }
    
    public var unlinkedCourtId: String?
    public var unlinkExpectation: XCTestExpectation?
    
    public func unlinkMatch(courtId: String) async {
        print("TestMock: unlinkMatch called for \(courtId)")
        lastSyncedCourtId = nil
        unlinkedCourtId = courtId
        syncCount += 1
        unlinkExpectation?.fulfill()
    }
}

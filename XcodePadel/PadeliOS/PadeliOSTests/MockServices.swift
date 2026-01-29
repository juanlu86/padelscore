import Foundation
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
    
    public var lastSyncedState: MatchState?
    public var syncCount = 0
    
    public func syncMatch(state: MatchState) {
        lastSyncedState = state
        syncCount += 1
        status = .synced
    }
}

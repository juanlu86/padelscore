import Foundation
import XCTest
import Combine
import PadelCore
@testable import PadeliOS

@MainActor
public class MockConnectivityProvider: ConnectivityProvider {
    public var receivedState: MatchState?
    public var receivedIsStarted: Bool?
    
    public var receivedStatePublisher: AnyPublisher<MatchState?, Never> {
        Just(receivedState).eraseToAnyPublisher()
    }
    
    public var receivedIsStartedPublisher: AnyPublisher<Bool?, Never> {
        Just(receivedIsStarted).eraseToAnyPublisher()
    }
    
    public let updatePublisher = PassthroughSubject<(MatchState, Bool), Never>()
    public let stateRequestPublisher = PassthroughSubject<Void, Never>()
    public var hasPendingRequest: Bool = false
    
    public var lastSentState: MatchState?
    public var lastSentIsStarted: Bool?
    public var sendCount = 0
    
    public var requestCount = 0
    public var persistExpectation: XCTestExpectation?
    
    public func send(state: MatchState, isStarted: Bool) {
        lastSentState = state
        lastSentIsStarted = isStarted
        sendCount += 1
    }
    
    public func persistState(state: MatchState, isStarted: Bool) {
        lastSentState = state
        lastSentIsStarted = isStarted
        persistExpectation?.fulfill()
    }
    
    public func requestLatestState() {
        requestCount += 1
    }
    
    public func clearPendingRequest() {
        hasPendingRequest = false
    }
    
    public func simulateUpdate(state: MatchState, isStarted: Bool) {
        receivedState = state
        receivedIsStarted = isStarted
        updatePublisher.send((state, isStarted))
    }
}

public class MockSyncProvider: SyncProvider {
    public var status: SyncService.Status = .idle
    
    public var statusPublisher: AnyPublisher<SyncService.Status, Never> {
        Just(status).eraseToAnyPublisher()
    }
    
    public var lastSyncedCourtId: String?
    public var lastSyncedState: MatchState?
    public var syncCount = 0
    
    public func syncMatch(state: MatchState, courtId: String? = nil) {
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
        lastSyncedCourtId = nil
        unlinkedCourtId = courtId
        syncCount += 1
        unlinkExpectation?.fulfill()
    }
}

import Foundation
import Combine
import PadelCore

public protocol ConnectivityProvider: AnyObject {
    var receivedState: MatchState? { get }
    var receivedIsStarted: Bool? { get }
    
    var receivedStatePublisher: AnyPublisher<MatchState?, Never> { get }
    var receivedIsStartedPublisher: AnyPublisher<Bool?, Never> { get }
    var updatePublisher: PassthroughSubject<(MatchState, Bool), Never> { get }
    
    func send(state: MatchState, isStarted: Bool)
}

public protocol SyncProvider: AnyObject {
    #if !os(watchOS)
    var status: SyncService.Status { get }
    var statusPublisher: AnyPublisher<SyncService.Status, Never> { get }
    func syncMatch(state: MatchState, courtId: String?)
    func syncMatchAsync(state: MatchState, courtId: String?) async throws
    func unlinkMatch(courtId: String) async
    #endif
}

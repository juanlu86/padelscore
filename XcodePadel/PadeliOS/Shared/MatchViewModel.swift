import SwiftUI
import Observation
import Combine
import PadelCore

@Observable
public class MatchViewModel {
    public var state: MatchState
    public var isMatchStarted: Bool = false
    #if !os(watchOS)
    public var syncStatus: SyncService.Status = .idle
    #endif
    
    private let logic = PadelLogic()
    private var history: [MatchState] = []
    private var cancellables = Set<AnyCancellable>()
    
    public init(state: MatchState = MatchState()) {
        self.state = state
        
        #if !os(watchOS)
        // Listen for sync status updates
        SyncService.shared.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
        #endif
        
        // Listen for updates from the other device
        Publishers.CombineLatest(
            ConnectivityService.shared.$receivedState,
            ConnectivityService.shared.$receivedIsStarted
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state, isStarted in
            if let state = state, let isStarted = isStarted {
                self?.handleRemoteStateUpdate(state, isStarted: isStarted)
            }
        }
        .store(in: &cancellables)
    }
    
    private func handleRemoteStateUpdate(_ newState: MatchState, isStarted: Bool) {
        print("📥 Received remote state update. Version: \(newState.version) (Current: \(state.version))")
        
        // Only accept updates if they have a newer or equal version
        // (Equal version is allowed to handle metadata-only syncs if they ever occur)
        guard newState.version >= state.version else {
            print("⚠️ Ignoring stale remote update (v\(newState.version) < v\(state.version))")
            return
        }
        
        // If the incoming version is strictly greater, it means it's a new "event"
        if newState.version > state.version {
            history.append(state)
        }
        
        withAnimation(.spring()) {
            self.state = newState
            self.isMatchStarted = isStarted
        }
    }
    
    public func startMatch() {
        isMatchStarted = true
        state.version += 1
        #if !os(watchOS)
        SyncService.shared.syncMatch(state: state)
        #endif
        ConnectivityService.shared.send(state: state, isStarted: isMatchStarted)
    }
    
    public func scorePoint(forTeam1: Bool) {
        // Automatically start match on first point if not already
        if !isMatchStarted { isMatchStarted = true }
        // Save current state to history before updating
        history.append(state)
        state = logic.scorePoint(forTeam1: forTeam1, currentState: state)
        #if !os(watchOS)
        SyncService.shared.syncMatch(state: state)
        #endif
        ConnectivityService.shared.send(state: state, isStarted: isMatchStarted)
    }
    
    public func undoPoint() {
        guard !history.isEmpty else { return }
        let nextVersion = state.version + 1
        state = history.removeLast()
        state.version = nextVersion
        
        #if !os(watchOS)
        SyncService.shared.syncMatch(state: state)
        #endif
        ConnectivityService.shared.send(state: state, isStarted: isMatchStarted)
    }
    
    public func finishMatch() {
        // Save state before termination
        history.append(state)
        
        // Record the current (incomplete) set games if any points/games played
        if state.team1Games > 0 || state.team2Games > 0 || state.team1Score != .zero || state.team2Score != .zero {
            state.completedSets.append(SetResult(team1Games: state.team1Games, team2Games: state.team2Games))
        }
        
        state.isMatchOver = true
        state.version += 1
        #if !os(watchOS)
        SyncService.shared.syncMatch(state: state)
        #endif
        ConnectivityService.shared.send(state: state, isStarted: isMatchStarted)
    }
    
    public func resetMatch() {
        history.removeAll()
        var newState = MatchState()
        newState.version = state.version + 1
        state = newState
        isMatchStarted = false
        #if !os(watchOS)
        SyncService.shared.syncMatch(state: state)
        #endif
        ConnectivityService.shared.send(state: state, isStarted: isMatchStarted)
    }
    
    public var canUndo: Bool {
        return !history.isEmpty
    }
}

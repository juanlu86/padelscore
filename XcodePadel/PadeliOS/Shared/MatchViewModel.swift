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
    
    // MARK: - Display Properties
    
    public var team1DisplayScore: String {
        state.isTieBreak ? "\(state.team1TieBreakPoints)" : state.team1Score.rawValue
    }
    
    public var team2DisplayScore: String {
        state.isTieBreak ? "\(state.team2TieBreakPoints)" : state.team2Score.rawValue
    }
    
    public var specialPointLabel: String? {
        guard state.team1Score == .forty && state.team2Score == .forty else { return nil }
        
        switch state.scoringSystem {
        case .goldenPoint:
            return "GOLDEN POINT"
        case .starPoint:
            return state.deuceCount >= 3 ? "STAR POINT" : nil
        case .standard:
            return nil
        }
    }
    
    // MARK: - Internal Dependencies
    private let logic = PadelLogic()
    private var history: [MatchState] = []
    private var cancellables = Set<AnyCancellable>()
    #if os(watchOS)
    private let workoutManager = WorkoutManager()
    #endif
    
    private let connectivity: ConnectivityProvider
    #if !os(watchOS)
    private let sync: SyncProvider
    #endif
    
    public init(
        state: MatchState = MatchState(),
        connectivity: ConnectivityProvider = ConnectivityService.shared,
        sync: SyncProvider? = nil // Defaulted below
    ) {
        var initialState = state
        if initialState.team1.isEmpty { initialState.team1 = "TEAM 1" }
        if initialState.team2.isEmpty { initialState.team2 = "TEAM 2" }
        self.state = initialState
        self.connectivity = connectivity
        
        #if !os(watchOS)
        self.sync = sync ?? SyncService.shared
        
        // Listen for sync status updates
        self.sync.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
        #endif
        
        // Listen for updates from the other device
        Publishers.CombineLatest(
            self.connectivity.receivedStatePublisher,
            self.connectivity.receivedIsStartedPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state, isStarted in
            if let state = state, let isStarted = isStarted {
                self?.handleRemoteStateUpdate(state, isStarted: isStarted)
            }
        }
        .store(in: &cancellables)
    }
    
    
    public func startMatch() {
        isMatchStarted = true
        state.version += 1
        #if !os(watchOS)
        sync.syncMatch(state: state)
        #else
        workoutManager.requestAuthorization()
        workoutManager.startWorkout()
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public func scorePoint(forTeam1: Bool) {
        // Automatically start match on first point if not already
        if !isMatchStarted { isMatchStarted = true }
        // Save current state to history before updating
        history.append(state)
        state = logic.scorePoint(forTeam1: forTeam1, currentState: state)
        #if !os(watchOS)
        sync.syncMatch(state: state)
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public func undoPoint() {
        guard !history.isEmpty else { return }
        let nextVersion = state.version + 1
        state = history.removeLast()
        state.isMatchOver = false // Ensure match is not over after undoing the finish
        state.version = nextVersion
        
        #if !os(watchOS)
        sync.syncMatch(state: state)
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public func finishMatch() {
        // Save state before termination
        history.append(state)
        
        // Record the current (incomplete) set games if any points/games played
        if state.team1Games > 0 || state.team2Games > 0 || state.team1Score != .zero || state.team2Score != .zero {
            state.completedSets.append(SetResult(team1Games: state.team1Games, team2Games: state.team2Games))
        }
        
        // Reset current set progress on finish to avoid duplication in UI
        state.team1Games = 0
        state.team2Games = 0
        state.team1Score = .zero
        state.team2Score = .zero
        state.team1TieBreakPoints = 0
        state.team2TieBreakPoints = 0
        state.isTieBreak = false
        
        state.isMatchOver = true
        state.version += 1
        #if !os(watchOS)
        sync.syncMatch(state: state)
        #else
        workoutManager.endWorkout()
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public func resetMatch() {
        history.removeAll()
        var newState = MatchState()
        // Preserve settings
        newState.scoringSystem = state.scoringSystem
        newState.useTieBreak = state.useTieBreak
        newState.isGrandSlam = state.isGrandSlam
        
        newState.version = state.version + 1
        state = newState
        isMatchStarted = false
        #if !os(watchOS)
        sync.syncMatch(state: state)
        #else
        workoutManager.endWorkout()
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public func updateTeamNames(team1: String, team2: String) {
        state.team1 = team1
        state.team2 = team2
        state.version += 1
        
        #if !os(watchOS)
        sync.syncMatch(state: state)
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public var canUndo: Bool {
        return !history.isEmpty
    }
}

// MARK: - Private Helpers
private extension MatchViewModel {
    func handleRemoteStateUpdate(_ newState: MatchState, isStarted: Bool) {
        print("📥 Received remote state update. Version: \(newState.version) (Current: \(state.version))")
        
        // Only accept updates if they have a newer or equal version
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
}

// MARK: - Protocols

public protocol ConnectivityProvider: AnyObject {
    var receivedState: MatchState? { get }
    var receivedIsStarted: Bool? { get }
    
    var receivedStatePublisher: AnyPublisher<MatchState?, Never> { get }
    var receivedIsStartedPublisher: AnyPublisher<Bool?, Never> { get }
    
    func send(state: MatchState, isStarted: Bool)
}

public protocol SyncProvider: AnyObject {
    #if !os(watchOS)
    var status: SyncService.Status { get }
    var statusPublisher: AnyPublisher<SyncService.Status, Never> { get }
    func syncMatch(state: MatchState)
    #endif
}

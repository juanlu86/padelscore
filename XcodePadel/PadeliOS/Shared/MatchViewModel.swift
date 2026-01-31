import SwiftUI
import Observation
import Combine
import PadelCore
#if !os(watchOS)
import FirebaseFirestore
#endif

@Observable
public class MatchViewModel {
    public var state: MatchState
    public var isMatchStarted: Bool = false
    #if !os(watchOS)
    private let courtLink = CourtLinkManager.shared
    #endif
    
    #if !os(watchOS)
    public var syncStatus: SyncService.Status = .idle
    #endif
    
    public var linkedCourtId: String {
        get {
            #if !os(watchOS)
            return courtLink.linkedCourtId
            #else
            return ""
            #endif
        }
        set {
            #if !os(watchOS)
            courtLink.link(courtId: newValue)
            #endif
        }
    }
    
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
            
        // Observe court link changes to trigger initial sync
        withObservationTracking {
            _ = courtLink.linkedCourtId
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let id = courtLink.linkedCourtId
                if !id.isEmpty {
                    try? await self.sync.syncMatchAsync(state: self.state, courtId: id)
                }
            }
        }
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
        
        #if os(watchOS)
        workoutManager.requestAuthorization()
        #endif
    }
    
    
    public func startMatch() {
        isMatchStarted = true
        state.version += 1
        #if os(watchOS)
        workoutManager.startWorkout()
        #endif
        propagateChange()
    }
    
    public func scorePoint(forTeam1: Bool) {
        // Automatically start match on first point if not already
        if !isMatchStarted { isMatchStarted = true }
        // Save current state to history before updating
        history.append(state)
        state = logic.scorePoint(forTeam1: forTeam1, currentState: state)
        propagateChange()
    }
    
    public func undoPoint() {
        guard !history.isEmpty else { return }
        let nextVersion = state.version + 1
        let currentTeam1 = state.team1
        let currentTeam2 = state.team2
        
        state = history.removeLast()
        state.team1 = currentTeam1
        state.team2 = currentTeam2
        state.isMatchOver = false // Ensure match is not over after undoing the finish
        state.version = nextVersion
        
        propagateChange()
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
        #if os(watchOS)
        workoutManager.endWorkout()
        #endif
        propagateChange()
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
        #if os(watchOS)
        workoutManager.endWorkout()
        #endif
        propagateChange()
    }
    
    public func updateTeamNames(team1: String, team2: String) {
        state.team1 = team1
        state.team2 = team2
        state.version += 1
        
        propagateChange()
    }
    
    public var canUndo: Bool {
        return !history.isEmpty
    }
    
    public func unlinkCurrentCourt() async {
        #if !os(watchOS)
        let courtId = linkedCourtId
        guard !courtId.isEmpty else { return }
        
        // 1. Clear local link
        courtLink.unlink()
        
        // 2. Tell backend
        await sync.unlinkMatch(courtId: courtId)
        #endif
    }
}

// MARK: - Private Helpers
private extension MatchViewModel {
    /// Centralized point to propagate local changes to both Watch and Cloud
    func propagateChange() {
        #if !os(watchOS)
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }

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
        
        #if !os(watchOS)
        // Gateway: Sync the received remote state to Firestore using our linked court ID
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
        #endif
    }
}

// MARK: - Remote Unlinking
#if !os(watchOS)
#endif

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
    func syncMatch(state: MatchState, courtId: String?)
    func syncMatchAsync(state: MatchState, courtId: String?) async throws
    func unlinkMatch(courtId: String) async
    #endif
}

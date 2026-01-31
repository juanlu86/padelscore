import SwiftUI
import Observation
import Combine
import PadelCore
#if !os(watchOS)
import FirebaseFirestore
#endif

@MainActor
@Observable
public class MatchViewModel {
    public var state: MatchState
    public var isMatchStarted: Bool = false
    private var hasActivated: Bool = false
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
            sync.syncMatch(state: state, courtId: linkedCourtId.isEmpty ? nil : linkedCourtId)
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
        connectivity: ConnectivityProvider? = nil,
        sync: SyncProvider? = nil
    ) {
        var initialState = state
        if initialState.team1.isEmpty { initialState.team1 = "TEAM 1" }
        if initialState.team2.isEmpty { initialState.team2 = "TEAM 2" }
        self.state = initialState
        self.connectivity = connectivity ?? ConnectivityService.shared
        
        #if !os(watchOS)
        self.sync = sync ?? SyncService.shared
        #endif
        
    }
    
    public func activate() {
        guard !hasActivated else { return }
        hasActivated = true
        
        #if !os(watchOS)
        // Listen for sync status updates
        self.sync.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
            
        // Initial sync if court is already linked
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let id = courtLink.linkedCourtId
            if !id.isEmpty {
                 try? await self.sync.syncMatchAsync(state: self.state, courtId: id)
            }
        }
        #endif
        
        #if os(watchOS)
        let platform = "watchOS"
        #else
        let platform = "iOS"
        #endif
        print("🛠️ MatchViewModel: Activating... Target: \(platform)")
        
        // 1. Listen for state updates from the other device
        self.connectivity.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, isStarted in
                print("📡 MatchViewModel: Received update. v\(state.version), isStarted: \(isStarted)")
                self?.handleRemoteStateUpdate(state, isStarted: isStarted)
            }
            .store(in: &cancellables)
            
        // 2. Listen for state requests from the other device (Peer asking us for the score)
        self.connectivity.stateRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                print("📥 MatchViewModel: Peer requested state. Sending current state...")
                self?.propagateChange()
            }
            .store(in: &cancellables)
            
        // 3. Initial Sync Strategy
        if let initialRemoteState = self.connectivity.receivedState,
           let initialIsStarted = self.connectivity.receivedIsStarted {
            print("🚀 MatchViewModel: Found existing remote state in ConnectivityService: v\(initialRemoteState.version)")
            handleRemoteStateUpdate(initialRemoteState, isStarted: initialIsStarted)
        } else {
            print("ℹ️ MatchViewModel: No initial remote state. Requesting from peer...")
            self.connectivity.requestLatestState()
        }
        
        // 4. Handle sticky requests that arrived during boot
        if self.connectivity.hasPendingRequest {
            print("📥 MatchViewModel: Found sticky peer request on startup. Responding...")
            propagateChange()
            self.connectivity.clearPendingRequest()
        }
        
        // 5. Proactive Broadcast: If we already have a match running, tell the peer immediately
        if isMatchStarted || state.version > 0 {
            print("📤 MatchViewModel: Proactively broadcasting active match on startup (v\(state.version))")
            propagateChange()
        }
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
    
    public func requestPermissions() {
        #if os(watchOS)
        workoutManager.requestAuthorization()
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
        connectivity.clearPendingRequest()
    }

    func handleRemoteStateUpdate(_ newState: MatchState, isStarted: Bool) {
        print("📥 MatchViewModel: Handling remote update. Version: \(newState.version) (Current: \(state.version)) isStarted: \(isStarted)")
        
        // Only accept updates if they have a newer version
        // (Allow equal version ONLY if we are syncing the 'isStarted' flag for the first time)
        guard newState.version > state.version || (newState.version == state.version && isStarted != self.isMatchStarted) else {
            print("♻️ Ignoring redundant/stale remote update (v\(newState.version) <= v\(state.version))")
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

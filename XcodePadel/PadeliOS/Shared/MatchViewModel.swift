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
    public var linkedCourtId: String = "" {
        didSet {
            let normalized = linkedCourtId.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if normalized != linkedCourtId {
                linkedCourtId = normalized
                return
            }
            UserDefaults.standard.set(normalized, forKey: "linkedCourtId")
            
            #if !os(watchOS)
            if !normalized.isEmpty {
                // RACE CONDITION FIX:
                // We must write the data FIRST before listening, otherwise the listener might
                // see an empty "liveMatch" (from before our write) and immediately unlink us.
                Task { @MainActor in
                    do {
                        try await sync.syncMatchAsync(state: state, courtId: normalized)
                        setupCourtListener(id: normalized)
                    } catch {
                        print("⚠️ Failed to perform initial sync for court \(normalized): \(error.localizedDescription)")
                        // Attempt to listen anyway, in case it was a transient network error
                        setupCourtListener(id: normalized)
                    }
                }
            } else {
                stopCourtListener()
            }
            #endif
        }
    }
    
    #if !os(watchOS)
    public var syncStatus: SyncService.Status = .idle
    private var courtListener: ListenerRegistration?
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
        
        // Load initial state
        self.linkedCourtId = UserDefaults.standard.string(forKey: "linkedCourtId") ?? ""
        
        // Listen for sync status updates
        self.sync.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
            
        if !linkedCourtId.isEmpty {
            setupCourtListener(id: linkedCourtId)
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
    }
    
    
    public func startMatch() {
        isMatchStarted = true
        state.version += 1
        #if !os(watchOS)
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
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
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
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
        
        #if !os(watchOS)
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
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
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
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
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
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
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
        #endif
        connectivity.send(state: state, isStarted: isMatchStarted)
    }
    
    public var canUndo: Bool {
        return !history.isEmpty
    }
    
    public func unlinkCurrentCourt() async {
        #if !os(watchOS)
        let courtId = linkedCourtId
        NSLog("ViewModel: unlinkCurrentCourt called with courtId: '%@'", courtId)
        guard !courtId.isEmpty else { return }
        
        // 1. Clear local link immediately for UI responsiveness
        await MainActor.run {
            self.linkedCourtId = ""
        }
        
        // 2. Tell backend to clear the match from the court
        NSLog("ViewModel: calling sync.unlinkMatch for %@", courtId)
        await sync.unlinkMatch(courtId: courtId)
        #endif
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
        
        #if !os(watchOS)
        // Gateway: Sync the received remote state to Firestore using our linked court ID
        let courtId = linkedCourtId.isEmpty ? nil : linkedCourtId
        sync.syncMatch(state: state, courtId: courtId)
        #endif
    }
}

// MARK: - Remote Unlinking
#if !os(watchOS)
private extension MatchViewModel {
    func setupCourtListener(id: String) {
        stopCourtListener()
        
        print("📡 Starting remote listener for court: \(id)")
        courtListener = Firestore.firestore().collection("courts").document(id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                
                // If the court's liveMatch is null or field is missing, it was reset by admin
                if snapshot.exists && snapshot.data()?["liveMatch"] == nil {
                    print("🚫 Court \(id) was reset/cleared by admin. Unlinking local device.")
                    Task { @MainActor in
                        withAnimation(.spring()) {
                            self.linkedCourtId = ""
                        }
                    }
                }
            }
    }
    
    func stopCourtListener() {
        courtListener?.remove()
        courtListener = nil
    }
}
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

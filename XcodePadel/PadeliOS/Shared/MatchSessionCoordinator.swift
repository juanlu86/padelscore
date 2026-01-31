import Foundation
import Combine
import PadelCore

#if !os(watchOS)
import FirebaseFirestore
#endif

/// Manages the active session's connectivity and synchronization bindings.
/// Takes over the responsibility of listening to Connectivity/Sync updates from MatchViewModel.
@MainActor
public class MatchSessionCoordinator {
    private weak var viewModel: MatchViewModel?
    private let connectivity: ConnectivityProvider
    #if !os(watchOS)
    private let sync: SyncProvider
    #endif
    
    private var cancellables = Set<AnyCancellable>()
    private var isActivated = false
    
    // MARK: - Initialization
    
    public init(
        viewModel: MatchViewModel,
        connectivity: ConnectivityProvider? = nil,
        sync: SyncProvider? = nil
    ) {
        self.viewModel = viewModel
        self.connectivity = connectivity ?? ConnectivityService.shared
        #if !os(watchOS)
        self.sync = sync ?? SyncService.shared
        #endif
    }
    
    // MARK: - Activation
    
    public func activate() {
        guard !isActivated, let viewModel = viewModel else { return }
        isActivated = true
        
        #if !os(watchOS)
        setupSyncBindings(viewModel: viewModel)
        #endif
        
        setupConnectivityBindings(viewModel: viewModel)
        handleInitialHandshake(viewModel: viewModel)
    }
    
    private func setupConnectivityBindings(viewModel: MatchViewModel) {
        // 1. Listen for state updates
        connectivity.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, isStarted in
                self?.handleRemoteStateUpdate(state, isStarted: isStarted)
            }
            .store(in: &cancellables)
            
        // 2. Respond to state requests
        connectivity.stateRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                print("📥 Coordinator: Peer requested state. Sending current state...")
                self?.propagateChange()
            }
            .store(in: &cancellables)
    }
    
    #if !os(watchOS)
    private func setupSyncBindings(viewModel: MatchViewModel) {
        sync.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak viewModel] status in
                viewModel?.syncStatus = status
            }
            .store(in: &cancellables)
            
        // Initial Cloud Sync check
        Task { [weak self, weak viewModel] in
            guard let self = self, let vm = viewModel else { return }
            let id = vm.linkedCourtId
            if !id.isEmpty {
                 try? await self.sync.syncMatchAsync(state: vm.state, courtId: id)
            }
        }
    }
    #endif
    
    // MARK: - Handshake Logic
    
    private func handleInitialHandshake(viewModel: MatchViewModel) {
        // 1. Check for existing data in ConnectivityService
        if let initialRemoteState = connectivity.receivedState,
           let initialIsStarted = connectivity.receivedIsStarted {
            print("🚀 Coordinator: Found existing remote state: v\(initialRemoteState.version)")
            handleRemoteStateUpdate(initialRemoteState, isStarted: initialIsStarted)
        } else {
            print("ℹ️ Coordinator: Requesting latest state from peer...")
            connectivity.requestLatestState()
        }
        
        // 2. Handle sticky requests
        if connectivity.hasPendingRequest {
            print("📥 Coordinator: Found sticky peer request. Responding...")
            propagateChange()
            connectivity.clearPendingRequest()
        }
        
        // 3. Proactive Broadcast
        if viewModel.isMatchStarted || viewModel.state.version > 0 {
            propagateChange()
        }
    }
    
    // MARK: - Actions
    
    func propagateChange() {
        guard let subVM = viewModel else { return }
        
        #if !os(watchOS)
        let courtId = subVM.linkedCourtId.isEmpty ? nil : subVM.linkedCourtId
        sync.syncMatch(state: subVM.state, courtId: courtId)
        #endif
        
        connectivity.send(state: subVM.state, isStarted: subVM.isMatchStarted)
        connectivity.clearPendingRequest()
    }
    
    // MARK: - State Handling
    
    private func handleRemoteStateUpdate(_ newState: MatchState, isStarted: Bool) {
        guard let vm = viewModel else { return }
        
        // Use the public method on VM to safe-guard state transitions
        vm.handleRemoteStateUpdate(newState, isStarted: isStarted)
    }
}

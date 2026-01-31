import Foundation
import WatchConnectivity
import Combine
import PadelCore

@Observable
public class ConnectivityService: NSObject, WCSessionDelegate, ConnectivityProvider {
    public static let shared = ConnectivityService()
    
    public var receivedState: MatchState?
    public var receivedIsStarted: Bool?
    
    public let updatePublisher = PassthroughSubject<(MatchState, Bool), Never>()
    public let stateRequestPublisher = PassthroughSubject<Void, Never>()
    public private(set) var hasPendingRequest: Bool = false
    
    public var receivedStatePublisher: AnyPublisher<MatchState?, Never> {
        // Keep for backward compatibility during migration if needed, 
        // but prefer Observation in new code.
        Just(receivedState).eraseToAnyPublisher()
    }
    
    public var receivedIsStartedPublisher: AnyPublisher<Bool?, Never> {
        Just(receivedIsStarted).eraseToAnyPublisher()
    }
    
    private var lastReceivedVersion: Int = -1
    private var pendingSync: (MatchState, Bool)?
    private var needsInitialSync: Bool = false
    
    // MARK: - Logging Helper
    private func log(_ message: String, isError: Bool = false) {
        #if DEBUG
        print(message)
        #else
        if isError {
            print(message)
        }
        #endif
    }
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            self.log("⏳ WCSession activation requested...")
        }
    }
    
    public func send(state: MatchState, isStarted: Bool) {
        let session = WCSession.default
        let isActivated = session.activationState == .activated
        
        guard isActivated else {
            self.log("⏳ ConnectivityService: Session not ready. Queuing pending update.")
            pendingSync = (state, isStarted)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            
            // IMPORTANT: Track the version we are sending so we don't process an echo of it later
            self.lastReceivedVersion = state.version
            
            let context: [String: Any] = [
                "matchState": data,
                "isStarted": isStarted,
                "timestamp": Date().timeIntervalSince1970 
            ]
            
            // 1. Preferred method (persists state, but eventually delivered)
            try session.updateApplicationContext(context)
            
            if session.isReachable {
                session.sendMessage(context, replyHandler: nil, errorHandler: { error in
                    self.log("⚠️ ConnectivityService: sendMessage failed: \(error.localizedDescription)", isError: true)
                })
            }
            
            pendingSync = nil
        } catch {
            self.log("❌ ConnectivityService: Failed to send match state: \(error.localizedDescription)", isError: true)
        }
    }
    
    /// Updates the application context without sending an interactive message.
    /// Use this to ensure the "broadcast buffer" remains current even when receiving remote updates.
    public func persistState(state: MatchState, isStarted: Bool) {
        let session = WCSession.default
        let isActivated = session.activationState == .activated
        
        guard isActivated else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            
            // IMPORTANT: Track the version we are sending so we don't process an echo of it later
            // (Even though we are persisting a remote update, we are effectively adopting it as our own truth)
            self.lastReceivedVersion = state.version
            
            let context: [String: Any] = [
                "matchState": data,
                "isStarted": isStarted,
                "timestamp": Date().timeIntervalSince1970 
            ]
            
            try session.updateApplicationContext(context)
             self.log("💾 ConnectivityService: Persisted state v\(state.version) to ApplicationContext")
        } catch {
             self.log("❌ ConnectivityService: Failed to persist state: \(error.localizedDescription)", isError: true)
        }
    }
    
    public func requestLatestState() {
        let session = WCSession.default
        let isActivated = session.activationState == .activated
        let isReachable = session.isReachable
        
        guard isActivated && isReachable else {
            self.log("ℹ️ ConnectivityService: Cannot request latest state yet (Activated: \(isActivated), Reachable: \(isReachable)). Queuing request.")
            needsInitialSync = true
            return 
        }
        
        self.log("📡 ConnectivityService: Requesting latest state from peer...")
        session.sendMessage(["requestState": true], replyHandler: nil) { error in
            self.log("⚠️ ConnectivityService: State request failed: \(error.localizedDescription)", isError: true)
        }
        needsInitialSync = false
    }
    
    public func clearPendingRequest() {
        if hasPendingRequest {
            self.log("🧹 ConnectivityService: Clearing sticky peer request")
            hasPendingRequest = false
        }
    }
    
    // MARK: - WCSessionDelegate
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            self.log("❌ ConnectivityService: WCSession activation failed: \(error.localizedDescription)", isError: true)
        } else {
            self.log("✅ ConnectivityService: WCSession activated with state: \(activationState.rawValue)")
            
            // NEW: Check for existing application context data on activation
            if !session.receivedApplicationContext.isEmpty {
                self.log("📦 ConnectivityService: Found existing application context on activation")
                processReceivedContext(session.receivedApplicationContext)
            } else {
                self.log("ℹ️ ConnectivityService: No previous application context found on activation")
            }
            
            // Retry pending sync if we have one
            if let pending = pendingSync {
                send(state: pending.0, isStarted: pending.1)
            }
            
            // Retry queued initial sync request
            if needsInitialSync {
                self.log("🔄 ConnectivityService: Retrying queued initial state request...")
                requestLatestState()
            }
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processReceivedContext(message)
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        processReceivedContext(message)
        replyHandler(["received": true])
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        processReceivedContext(applicationContext)
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        processReceivedContext(userInfo)
    }
    
    private func processReceivedContext(_ context: [String : Any]) {
        if context["requestState"] as? Bool == true {
            self.log("📥 ConnectivityService: Received state request from peer")
            hasPendingRequest = true
            stateRequestPublisher.send()
            return
        }
        
        // STALENESS CHECK: Ignore contexts older than 3 hours
        if let timestamp = context["timestamp"] as? TimeInterval {
            let age = Date().timeIntervalSince1970 - timestamp
            if age > (3 * 3600) { // 3 hours
                self.log("🕰️ ConnectivityService: Ignoring stale context (Age: \(Int(age))s)")
                return
            }
        } else {
            // Optional: If no timestamp exists (legacy data), decide whether to accept or drop.
            // For now, we'll log it but accept it to avoid breaking valid legacy sessions during upgrade,
            // unless the user explicitly wants to force start-fresh.
            self.log("⚠️ ConnectivityService: Context has no timestamp. Accepting potentially stale data.")
        }
        
        self.log("🔍 ConnectivityService: Processing received context/message...")
        guard let data = context["matchState"] as? Data else { 
            self.log("⚠️ ConnectivityService: No 'matchState' found in context. Keys: \(context.keys)", isError: true)
            return 
        }
        
        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(MatchState.self, from: data)
            
            // LOGICAL VERSION FILTERING
            self.log("📈 ConnectivityService: Received v\(state.version). Last known: \(lastReceivedVersion)")
            guard state.version > lastReceivedVersion else {
                self.log("♻️ ConnectivityService: Ignoring stale/already processed update")
                return
            }
            
            self.lastReceivedVersion = state.version
            let isStarted = context["isStarted"] as? Bool ?? true
            
            Task { @MainActor in
                self.receivedState = state
                self.receivedIsStarted = isStarted
                self.updatePublisher.send((state, isStarted))
                self.log("📩 ConnectivityService: UI state updated to v\(state.version) (isStarted: \(isStarted))")
            }
        } catch {
            self.log("❌ ConnectivityService: Failed to decode received match state: \(error.localizedDescription)", isError: true)
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            self.log("📡 ConnectivityService: Peer became reachable. Checking for sync needs...")
            
            // 1. If we needed to pull state, do it now
            if needsInitialSync {
                requestLatestState()
            }
            
            // 2. If we had a locally queued update to share, push it now
            if let pending = pendingSync {
                self.log("📤 ConnectivityService: Pushing pending sync after reachability restoration")
                send(state: pending.0, isStarted: pending.1)
            }
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) { }
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

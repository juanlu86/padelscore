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
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("⏳ WCSession activation requested...")
        }
    }
    
    public func send(state: MatchState, isStarted: Bool) {
        let session = WCSession.default
        let isActivated = session.activationState == .activated
        
        print("📤 ConnectivityService: Attempting to send state v\(state.version). Activated: \(isActivated), Reachable: \(session.isReachable)")
        
        guard isActivated else {
            print("⏳ ConnectivityService: Session not ready. Queuing pending update.")
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
            
            // 2. Secondary method (queued, better for simulators and background)
            session.transferUserInfo(context)
            
            print("✅ ConnectivityService: Context/UserInfo transfer initiated")
            
            if session.isReachable {
                session.sendMessage(context, replyHandler: { reply in
                    print("✅ ConnectivityService: Peer acknowledged update v\(state.version)")
                }, errorHandler: { error in
                    print("⚠️ ConnectivityService: sendMessage failed: \(error.localizedDescription)")
                })
                print("📤 ConnectivityService: sendMessage emitted")
            } else {
                print("⚠️ ConnectivityService: Skipping sendMessage because session is NOT reachable (falling back to Context/UserInfo)")
            }
            
            pendingSync = nil
        } catch {
            print("❌ ConnectivityService: Failed to send match state: \(error.localizedDescription)")
        }
    }
    
    public func requestLatestState() {
        let session = WCSession.default
        let isActivated = session.activationState == .activated
        let isReachable = session.isReachable
        
        guard isActivated && isReachable else {
            print("ℹ️ ConnectivityService: Cannot request latest state yet (Activated: \(isActivated), Reachable: \(isReachable)). Queuing request.")
            needsInitialSync = true
            return 
        }
        
        print("📡 ConnectivityService: Requesting latest state from peer...")
        session.sendMessage(["requestState": true], replyHandler: nil) { error in
            print("⚠️ ConnectivityService: State request failed: \(error.localizedDescription)")
        }
        needsInitialSync = false
    }
    
    public func clearPendingRequest() {
        if hasPendingRequest {
            print("🧹 ConnectivityService: Clearing sticky peer request")
            hasPendingRequest = false
        }
    }
    
    // MARK: - WCSessionDelegate
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ ConnectivityService: WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ ConnectivityService: WCSession activated with state: \(activationState.rawValue)")
            
            // NEW: Check for existing application context data on activation
            if !session.receivedApplicationContext.isEmpty {
                print("📦 ConnectivityService: Found existing application context on activation")
                processReceivedContext(session.receivedApplicationContext)
            } else {
                print("ℹ️ ConnectivityService: No previous application context found on activation")
            }
            
            // Retry pending sync if we have one
            if let pending = pendingSync {
                send(state: pending.0, isStarted: pending.1)
            }
            
            // Retry queued initial sync request
            if needsInitialSync {
                print("🔄 ConnectivityService: Retrying queued initial state request...")
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
            print("📥 ConnectivityService: Received state request from peer")
            hasPendingRequest = true
            stateRequestPublisher.send()
            return
        }
        
        print("🔍 ConnectivityService: Processing received context/message...")
        guard let data = context["matchState"] as? Data else { 
            print("⚠️ ConnectivityService: No 'matchState' found in context. Keys: \(context.keys)")
            return 
        }
        
        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(MatchState.self, from: data)
            
            // LOGICAL VERSION FILTERING
            print("📈 ConnectivityService: Received v\(state.version). Last known: \(lastReceivedVersion)")
            guard state.version > lastReceivedVersion else {
                print("♻️ ConnectivityService: Ignoring stale/already processed update")
                return
            }
            
            self.lastReceivedVersion = state.version
            let isStarted = context["isStarted"] as? Bool ?? true
            
            Task { @MainActor in
                self.receivedState = state
                self.receivedIsStarted = isStarted
                self.updatePublisher.send((state, isStarted))
                print("📩 ConnectivityService: UI state updated to v\(state.version) (isStarted: \(isStarted))")
            }
        } catch {
            print("❌ ConnectivityService: Failed to decode received match state: \(error.localizedDescription)")
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("📡 ConnectivityService: Peer became reachable. Checking for sync needs...")
            
            // 1. If we needed to pull state, do it now
            if needsInitialSync {
                requestLatestState()
            }
            
            // 2. If we had a locally queued update to share, push it now
            if let pending = pendingSync {
                print("📤 ConnectivityService: Pushing pending sync after reachability restoration")
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

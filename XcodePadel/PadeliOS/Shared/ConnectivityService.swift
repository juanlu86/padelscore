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
        
        guard isActivated else {
            print("⏳ Session not ready. Queuing pending update.")
            pendingSync = (state, isStarted)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            
            // Update local tracking so we don't process OLDER versions later
            self.lastReceivedVersion = state.version
            
            let context: [String: Any] = [
                "matchState": data,
                "isStarted": isStarted,
                "timestamp": Date().timeIntervalSince1970 
            ]
            
            try session.updateApplicationContext(context)
            
            if session.isReachable {
                session.sendMessage(context, replyHandler: nil) { error in
                    print("⚠️ sendMessage failed: \(error.localizedDescription)")
                }
            }
            
            pendingSync = nil
        } catch {
            print("❌ Failed to send match state: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activated with state: \(activationState.rawValue)")
            
            // Retry pending sync if we have one
            if let pending = pendingSync {
                send(state: pending.0, isStarted: pending.1)
            }
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processReceivedContext(message)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        processReceivedContext(applicationContext)
    }
    
    private func processReceivedContext(_ context: [String : Any]) {
        guard let data = context["matchState"] as? Data else { return }
        
        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(MatchState.self, from: data)
            
            // LOGICAL VERSION FILTERING
            guard state.version > lastReceivedVersion else {
                return
            }
            
            self.lastReceivedVersion = state.version
            let isStarted = context["isStarted"] as? Bool ?? true
            
            Task { @MainActor in
                self.receivedState = state
                self.receivedIsStarted = isStarted
                self.updatePublisher.send((state, isStarted))
                print("📩 Received state update v\(state.version)")
            }
        } catch {
            print("❌ Failed to decode received match state: \(error.localizedDescription)")
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) { }
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

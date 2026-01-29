import Foundation
import WatchConnectivity
import Combine
import PadelCore

public class ConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = ConnectivityService()
    
    @Published public var receivedState: MatchState?
    @Published public var receivedIsStarted: Bool?
    
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
        print("📡 Attempting to send. Session state: \(session.activationState.rawValue) (Activated: \(isActivated))")
        
        guard isActivated else {
            print("⏳ Session not ready. Queuing pending update.")
            pendingSync = (state, isStarted)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
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
                print("⚡️ sendMessage sent (high priority)")
            }
            
            print("📲 Context update sent. Started: \(isStarted)")
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
            print("📱 WCSession Reachable: \(session.isReachable)")
            #if os(iOS)
            print("⌚️ Is Paired: \(session.isPaired), Watch App Installed: \(session.isWatchAppInstalled)")
            #endif
            
            // Retry pending sync if we have one
            if let pending = pendingSync {
                print("🔄 Retrying pending sync after activation...")
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
            let isStarted = context["isStarted"] as? Bool ?? true
            
            DispatchQueue.main.async {
                self.receivedState = state
                self.receivedIsStarted = isStarted
                print("📩 Received state update (Started: \(isStarted)) via \(WCSession.isSupported() ? "WCSession" : "Unknown")")
                
                #if !os(watchOS)
                SyncService.shared.syncMatch(state: state)
                #endif
            }
        } catch {
            print("❌ Failed to decode received match state: \(error.localizedDescription)")
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession became inactive")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession deactivated. Re-activating...")
        WCSession.default.activate()
    }
    
    public func sessionWatchStateDidChange(_ session: WCSession) {
        print("⌚️ Watch State Changed:")
        print("   - Is Paired: \(session.isPaired)")
        print("   - Watch App Installed: \(session.isWatchAppInstalled)")
        print("   - Complication Enabled: \(session.isComplicationEnabled)")
    }
    #endif
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print("📡 Reachability Changed: \(session.isReachable)")
    }
}

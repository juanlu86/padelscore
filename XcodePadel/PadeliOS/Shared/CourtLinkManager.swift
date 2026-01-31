import Foundation
import Combine
import Observation
#if !os(watchOS)
import FirebaseFirestore
#endif

/// Handles the persistence and synchronization of the linked Court ID.
/// Also manages the Firestore listener for remote unlinking.
@MainActor
@Observable
public class CourtLinkManager {
    public var linkedCourtId: String = ""
    
    private let userDefaultsKey = "linkedCourtId"
    #if !os(watchOS)
    private var courtListener: FirebaseFirestore.ListenerRegistration?
    #endif
    
    public static let shared = CourtLinkManager()
    
    public init() {
        self.linkedCourtId = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
    }
    
    public func link(courtId: String) {
        let normalized = courtId.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized != linkedCourtId else { return }
        
        self.linkedCourtId = normalized
        UserDefaults.standard.set(normalized, forKey: userDefaultsKey)
        
        #if !os(watchOS)
        if !normalized.isEmpty {
            setupCourtListener(id: normalized)
        } else {
            stopCourtListener()
        }
        #endif
    }
    
    public func unlink() {
        link(courtId: "")
    }
    
    #if DEBUG
    public func resetForTesting() {
        linkedCourtId = ""
        #if !os(watchOS)
        stopCourtListener()
        #endif
    }
    #endif
    
    #if !os(watchOS)
    public func setupCourtListener(id: String) {
        stopCourtListener()
        
        print("📡 CourtLinkManager: Starting remote listener for court: \(id)")
        courtListener = FirebaseFirestore.Firestore.firestore().collection("courts").document(id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                
                if snapshot.exists && snapshot.data()?["liveMatch"] == nil {
                    // print("🚫 CourtLinkManager: Court \(id) reset by admin. Unlinking.")
                    // Task { @MainActor in
                    //     self.unlink()
                    // }
                    print("⚠️ CourtLinkManager: Court \(id) has no live match. Keeping link active.")
                }
            }
    }
    
    public func stopCourtListener() {
        courtListener?.remove()
        courtListener = nil
    }
    #endif
}

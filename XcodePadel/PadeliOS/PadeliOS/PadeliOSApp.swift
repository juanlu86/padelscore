//
//  PadeliOSApp.swift
//  PadeliOS
//
//  Created by Juan Luis Lopez Muñoz on 28/1/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let providerFactory = PadelAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-UseLocalhost") {
            print("🚨 E2E MODE ENABLED: Connecting to Localhost Emulators 🚨")
            
            // Firestore
            let settings = Firestore.firestore().settings
            settings.host = "127.0.0.1:8080"
            settings.cacheSettings = MemoryCacheSettings() // Disable persistence for tests
            settings.isSSLEnabled = false
            Firestore.firestore().settings = settings
            
            // Auth
            // Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099) 
            // Note: Auth emulator requires import FirebaseAuth, which might not be needed if we don't auth in iOS app yet.
            // But good to have if we expand.
        }
        
        // Initialize Watch Connectivity early
        _ = ConnectivityService.shared
        
        return true
    }
}

@main
struct PadeliOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            iPhoneMatchView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Ensure any pending debounced sync is captured before suspension
                SyncService.shared.flushPendingSync()
            }
        }
    }
}

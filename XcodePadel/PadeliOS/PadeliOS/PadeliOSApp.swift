//
//  PadeliOSApp.swift
//  PadeliOS
//
//  Created by Juan Luis Lopez Muñoz on 28/1/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        #if DEBUG
        let settings = FirestoreSettings()
        settings.host = "127.0.0.1:8080"
        settings.isSSLEnabled = false
        settings.isPersistenceEnabled = true // Enable offline persistence
        Firestore.firestore().settings = settings
        print("🔥 Firestore Emulator Connected: 127.0.0.1:8080")
        #endif
        
        // Initialize Watch Connectivity early
        _ = ConnectivityService.shared
        
        return true
    }
}

@main
struct PadeliOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            iPhoneMatchView()
        }
    }
}

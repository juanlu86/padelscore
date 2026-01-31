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
        
        #if DEBUG
        // let settings = FirestoreSettings()
        // settings.host = "localhost:8080"
        // settings.isSSLEnabled = false
        // settings.isPersistenceEnabled = false // Disable persistence to surface errors immediately
        // Firestore.firestore().settings = settings
        // print("🔥 Firestore Emulator Connected: localhost:8080")
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

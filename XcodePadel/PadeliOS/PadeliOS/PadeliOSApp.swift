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
        // Firestore Emulator configuration removed for Production/App Check testing
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

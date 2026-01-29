//
//  PadeliOSApp.swift
//  PadeliOS Watch App
//
//  Created by Juan Luis Lopez Muñoz on 28/1/26.
//

import SwiftUI

@main
struct PadeliOS_Watch_AppApp: App {
    init() {
        // Initialize Watch Connectivity early
        _ = ConnectivityService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            WatchScoringView()
        }
    }
}

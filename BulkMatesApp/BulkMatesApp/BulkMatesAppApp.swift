//
//  BulkMatesAppApp.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI
import Firebase

@main
struct BulkMatesAppApp: App {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Configure Firebase when the app launches
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(firebaseManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    var body: some View {
        if firebaseManager.isAuthenticated {
            MainTabView()
                .environmentObject(firebaseManager)
        } else {
            ContentView()
                .environmentObject(firebaseManager)
        }
    }
}

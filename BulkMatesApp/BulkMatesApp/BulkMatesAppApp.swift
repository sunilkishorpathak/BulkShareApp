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
    // NO AppDelegate - removing it to let Firebase use pure reCAPTCHA mode
    // @UIApplicationDelegateAdaptor breaks Firebase swizzling

    @StateObject private var firebaseManager = FirebaseManager.shared

    init() {
        // Configure Firebase when the app launches
        FirebaseApp.configure()
        print("🔥 Firebase configured - NO AppDelegate, pure reCAPTCHA mode")
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

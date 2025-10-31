//
//  BulkMatesAppApp.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI
import Firebase
import FirebaseAuth
import UIKit

// Minimal AppDelegate ONLY for notification forwarding - no APNs token setup
class MinimalAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification notification: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📬 Forwarding notification to Firebase")
        // Just forward to Firebase, don't try to set APNs token
        if Auth.auth().canHandleNotification(notification) {
            print("✅ Firebase handled notification")
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }
}

@main
struct BulkMatesAppApp: App {
    // Minimal AppDelegate ONLY for notification forwarding
    @UIApplicationDelegateAdaptor(MinimalAppDelegate.self) var appDelegate

    @StateObject private var firebaseManager = FirebaseManager.shared

    init() {
        // Configure Firebase when the app launches
        FirebaseApp.configure()
        print("🔥 Firebase configured with minimal AppDelegate (notification forwarding only)")
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

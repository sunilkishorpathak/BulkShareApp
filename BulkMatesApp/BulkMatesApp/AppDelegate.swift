//
//  AppDelegate.swift
//  BulkMatesApp
//
//  AppDelegate for handling push notifications registration
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Configure Firebase first (if not already configured)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured in AppDelegate")
        } else {
            print("🔥 Firebase already configured")
        }

        // Register for remote notifications (required for Firebase Phone Auth)
        registerForRemoteNotifications(application)

        return true
    }

    // Register for remote notifications
    private func registerForRemoteNotifications(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }

    // Called when APNs registration succeeds
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ APNs registration successful")
        print("📱 Device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // Ensure Firebase is configured before accessing Auth
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase not configured yet, cannot set APNs token")
            return
        }

        print("🔥 Firebase is configured, setting APNs token...")

        // Give Firebase Auth a moment to fully initialize before setting token
        // This prevents crashes from Auth singleton not being fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Get the default Firebase app
            guard let app = FirebaseApp.app() else {
                print("❌ No default Firebase app found")
                return
            }

            print("✅ Got Firebase app: \(app.name)")

            // Get Auth instance for this app
            let auth = Auth.auth(app: app)
            print("✅ Got Auth instance for app")

            // Pass the device token to Firebase Auth
            // Use .sandbox for debug builds, .prod for release/TestFlight
            #if DEBUG
            let tokenType: AuthAPNSTokenType = .sandbox
            print("🔧 Setting APNs token type: SANDBOX (debug build)")
            #else
            let tokenType: AuthAPNSTokenType = .prod
            print("🔧 Setting APNs token type: PRODUCTION (release build)")
            #endif

            auth.setAPNSToken(deviceToken, type: tokenType)
            print("✅ APNs token successfully set to Firebase Auth")
        }
    }

    // Called when APNs registration fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ APNs registration failed: \(error.localizedDescription)")
    }

    // Handle remote notification
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification notification: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Pass notification to Firebase Auth
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }

        completionHandler(.newData)
    }
}

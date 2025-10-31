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

        // Register for remote notifications
        // Let Firebase's automatic swizzling handle APNs token setup
        print("ℹ️ Registering for remote notifications - Firebase will auto-handle APNs")
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

        // Swizzling doesn't work with @UIApplicationDelegateAdaptor, so we must manually set the token
        // Give Firebase a moment to initialize, then try to set the token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.setAPNSToken(deviceToken)
        }
    }

    // Safely set the APNs token with Firebase Auth
    private func setAPNSToken(_ deviceToken: Data) {
        print("🔧 Attempting to set APNs token with Firebase Auth...")

        // Verify Firebase is configured
        guard let app = FirebaseApp.app() else {
            print("❌ Firebase app not found, cannot set APNs token")
            return
        }
        print("✅ Firebase app exists: \(app.name)")

        // Try to set the token with comprehensive error handling
        do {
            // Get Auth instance using the app
            let auth = Auth.auth(app: app)

            // Determine token type based on build configuration
            #if DEBUG
            let tokenType: AuthAPNSTokenType = .sandbox
            print("🔧 Using SANDBOX token type for debug build")
            #else
            let tokenType: AuthAPNSTokenType = .prod
            print("🔧 Using PRODUCTION token type for release build")
            #endif

            // This is the line that was crashing before
            // If it crashes, we'll catch it or at least see where
            print("🔧 About to call setAPNSToken...")
            auth.setAPNSToken(deviceToken, type: tokenType)
            print("✅ Successfully set APNs token with Firebase Auth!")

        } catch {
            print("❌ Caught error while setting APNs token: \(error)")
            print("ℹ️ Will fall back to reCAPTCHA verification")
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

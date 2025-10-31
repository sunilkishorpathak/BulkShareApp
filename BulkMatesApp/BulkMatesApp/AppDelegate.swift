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

        // DO NOT register for remote notifications - we're using pure reCAPTCHA mode
        // APNs token setting was causing crashes, so we're using reCAPTCHA only
        print("ℹ️ Skipping remote notification registration - using reCAPTCHA-only mode")

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

        // NOTE: We're NOT setting the APNs token to Firebase Auth because it's causing crashes
        // Instead, we'll rely on reCAPTCHA verification which doesn't require APNs
        // This is a valid fallback for phone verification
        print("ℹ️ Skipping APNs token setup - will use reCAPTCHA verification instead")
        print("ℹ️ Phone verification will work via reCAPTCHA flow")
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

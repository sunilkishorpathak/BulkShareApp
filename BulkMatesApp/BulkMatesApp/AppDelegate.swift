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

        // MUST register for remote notifications to satisfy Firebase's checks
        // Even though we won't use APNs, we need this to avoid ERROR_NOTIFICATION_NOT_FORWARDED
        print("ℹ️ Registering for remote notifications (required by Firebase)")
        application.registerForRemoteNotifications()

        return true
    }

    // Called when APNs registration succeeds
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ APNs device token received")
        print("📱 Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // DO NOT call Auth.auth().setAPNSToken() - it crashes
        // We're setting up notifications only to satisfy Firebase's checks
        print("ℹ️ Not configuring APNs with Firebase (will use reCAPTCHA)")
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
        print("📬 Received remote notification")
        print("📬 Notification payload: \(notification)")

        // Pass notification to Firebase Auth
        if Auth.auth().canHandleNotification(notification) {
            print("✅ Firebase Auth handled the notification")
            completionHandler(.noData)
            return
        }

        print("ℹ️ Notification not handled by Firebase Auth")
        completionHandler(.newData)
    }
}

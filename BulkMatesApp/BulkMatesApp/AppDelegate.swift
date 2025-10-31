//
//  AppDelegate.swift
//  BulkMatesApp
//
//  AppDelegate for handling push notifications registration
//

import UIKit
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

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

        // Pass the device token to Firebase Auth
        // Use .sandbox for debug builds, .prod for release/TestFlight
        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        print("🔧 APNs token type: SANDBOX (debug build)")
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        print("🔧 APNs token type: PRODUCTION (release build)")
        #endif
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

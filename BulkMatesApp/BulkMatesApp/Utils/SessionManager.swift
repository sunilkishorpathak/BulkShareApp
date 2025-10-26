//
//  SessionManager.swift
//  BulkMatesApp
//
//  Session management and auto-logout after inactivity
//

import Foundation
import Combine
import FirebaseAuth

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var isSessionActive = true
    @Published var showExpiryWarning = false
    @Published var remainingTime: TimeInterval = 0

    private var sessionTimer: Timer?
    private var lastActivityDate: Date = Date()
    private var sessionDuration: TimeInterval {
        let hours = UserDefaults.standard.integer(forKey: "autoLogoutDuration")
        if hours == 0 {
            return .infinity  // Never expire
        }
        return TimeInterval(hours * 60 * 60)  // Convert hours to seconds
    }
    private let warningTime: TimeInterval = 5 * 60  // 5 minutes before expiry

    private init() {
        setupActivityMonitoring()

        // Load last activity date from UserDefaults
        if let savedDate = UserDefaults.standard.object(forKey: "lastActivityDate") as? Date {
            lastActivityDate = savedDate
        }
    }

    /// Start a new session
    func startSession() {
        lastActivityDate = Date()
        isSessionActive = true
        showExpiryWarning = false
        startSessionTimer()

        print("📱 Session started at \(lastActivityDate)")
    }

    /// End the current session
    func endSession() {
        isSessionActive = false
        sessionTimer?.invalidate()
        sessionTimer = nil

        print("📱 Session ended")
    }

    /// Reset activity timer (called on user interaction)
    func resetActivity() {
        lastActivityDate = Date()
        showExpiryWarning = false
        UserDefaults.standard.set(lastActivityDate, forKey: "lastActivityDate")
    }

    /// Extend session when user responds to warning
    func extendSession() {
        lastActivityDate = Date()
        showExpiryWarning = false
        UserDefaults.standard.set(lastActivityDate, forKey: "lastActivityDate")

        print("📱 Session extended")
    }

    // MARK: - Private Methods

    private func startSessionTimer() {
        // Invalidate existing timer
        sessionTimer?.invalidate()

        // Don't start timer if duration is infinity (never expire)
        if sessionDuration == .infinity {
            return
        }

        // Create new timer that fires every minute
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSession()
        }
    }

    private func checkSession() {
        let elapsed = Date().timeIntervalSince(lastActivityDate)
        let remaining = sessionDuration - elapsed

        remainingTime = max(remaining, 0)

        // Show warning 5 minutes before expiry
        if remaining <= warningTime && remaining > 0 && !showExpiryWarning {
            print("⚠️ Session expiring soon: \(Int(remaining / 60)) minutes remaining")
            DispatchQueue.main.async {
                self.showExpiryWarning = true
            }
        }

        // Session expired
        if remaining <= 0 {
            print("❌ Session expired")
            expireSession()
        }
    }

    private func expireSession() {
        endSession()

        // Logout user
        do {
            try Auth.auth().signOut()
            print("🔓 User logged out due to session expiry")
        } catch {
            print("❌ Error logging out: \(error.localizedDescription)")
        }

        // Post notification to update UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name.sessionExpired, object: nil)
        }
    }

    private func setupActivityMonitoring() {
        // Monitor app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        print("📱 App became active")

        // Check if session is still valid when app becomes active
        if isSessionActive {
            checkSession()

            // Restart timer if it was invalidated
            if sessionTimer == nil || !sessionTimer!.isValid {
                startSessionTimer()
            }
        }
    }

    @objc private func appDidEnterBackground() {
        print("📱 App entered background")

        // Save last activity time
        UserDefaults.standard.set(lastActivityDate, forKey: "lastActivityDate")
    }

    @objc private func appWillTerminate() {
        print("📱 App will terminate")

        // Save last activity time
        UserDefaults.standard.set(lastActivityDate, forKey: "lastActivityDate")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        sessionTimer?.invalidate()
    }
}

// MARK: - Notification Names

extension NSNotification.Name {
    static let sessionExpired = NSNotification.Name("sessionExpired")
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private enum Keys {
        static let autoLogoutDuration = "autoLogoutDuration"
    }

    var autoLogoutDuration: Int {
        get {
            let duration = integer(forKey: Keys.autoLogoutDuration)
            return duration == 0 ? 8 : duration  // Default 8 hours
        }
        set {
            set(newValue, forKey: Keys.autoLogoutDuration)
        }
    }
}

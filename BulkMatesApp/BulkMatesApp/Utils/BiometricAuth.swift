//
//  BiometricAuth.swift
//  BulkMatesApp
//
//  Biometric authentication helper (Face ID / Touch ID)
//

import LocalAuthentication
import Foundation

class BiometricAuth {
    static let shared = BiometricAuth()

    enum BiometricType {
        case none
        case touchID
        case faceID

        var displayName: String {
            switch self {
            case .none:
                return "Not Available"
            case .touchID:
                return "Touch ID"
            case .faceID:
                return "Face ID"
            }
        }

        var iconName: String {
            switch self {
            case .none:
                return "lock.fill"
            case .touchID:
                return "touchid"
            case .faceID:
                return "faceid"
            }
        }
    }

    enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case failed
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case biometryLockout
        case unknown

        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
            case .failed:
                return "Biometric authentication failed"
            case .userCancel:
                return "Authentication was cancelled"
            case .userFallback:
                return "User chose to enter password"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Passcode is not set on this device"
            case .biometryLockout:
                return "Too many failed attempts. Please try again later"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }

    private init() {}

    /// Get the biometric type available on the device
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            case .none:
                return .none
            @unknown default:
                return .none
            }
        }

        return .touchID  // Fallback for older iOS
    }

    /// Check if biometric authentication is available
    func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Authenticate using biometrics
    func authenticate(reason: String? = nil, completion: @escaping (Bool, BiometricError?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                let biometricError = mapLAError(error)
                completion(false, biometricError)
            } else {
                completion(false, .notAvailable)
            }
            return
        }

        // Set context options
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Password"

        let defaultReason = "Authenticate to access BulkMates"
        let authReason = reason ?? defaultReason

        // Perform biometric authentication
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: authReason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    if let error = error as? NSError {
                        let biometricError = self.mapLAError(error)
                        completion(false, biometricError)
                    } else {
                        completion(false, .unknown)
                    }
                }
            }
        }
    }

    /// Authenticate using biometrics with async/await
    @available(iOS 15.0, *)
    func authenticate(reason: String? = nil) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            authenticate(reason: reason) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: BiometricError.unknown)
                    }
                }
            }
        }
    }

    // MARK: - Private Helper Methods

    private func mapLAError(_ error: NSError) -> BiometricError {
        guard let laError = LAError.Code(rawValue: error.code) else {
            return .unknown
        }

        switch laError {
        case .authenticationFailed:
            return .failed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .biometryLockout
        default:
            return .unknown
        }
    }
}

// MARK: - BiometricError Conformance

extension BiometricAuth.BiometricError: LocalizedError {
    var errorDescription: String? {
        return self.localizedDescription
    }
}

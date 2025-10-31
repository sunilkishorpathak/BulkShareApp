//
//  KeychainHelper.swift
//  BulkMatesApp
//
//  Secure storage for user credentials
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Save Password
    func savePassword(email: String, password: String) -> Bool {
        // Delete any existing password first
        deletePassword(for: email)

        // Prepare data
        guard let passwordData = password.data(using: .utf8) else {
            print("❌ Failed to convert password to data")
            return false
        }

        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Save to keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("✅ Password saved to Keychain for: \(email)")
            return true
        } else {
            print("❌ Failed to save password to Keychain. Status: \(status)")
            return false
        }
    }

    // MARK: - Retrieve Password
    func getPassword(for email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let passwordData = result as? Data,
           let password = String(data: passwordData, encoding: .utf8) {
            print("✅ Password retrieved from Keychain for: \(email)")
            return password
        } else {
            print("❌ Failed to retrieve password from Keychain. Status: \(status)")
            return nil
        }
    }

    // MARK: - Delete Password
    func deletePassword(for email: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Password deleted from Keychain for: \(email)")
            return true
        } else {
            print("❌ Failed to delete password from Keychain. Status: \(status)")
            return false
        }
    }

    // MARK: - Delete All Passwords
    func deleteAllPasswords() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ All passwords deleted from Keychain")
            return true
        } else {
            print("❌ Failed to delete all passwords from Keychain. Status: \(status)")
            return false
        }
    }
}

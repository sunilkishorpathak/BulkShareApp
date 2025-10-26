//
//  User.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  User.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation

// MARK: - Address Model

struct Address: Codable, Equatable {
    var street: String?
    var city: String
    var state: String
    var postalCode: String
    var country: String
    var latitude: Double?
    var longitude: Double?

    var fullAddress: String {
        var components: [String] = []
        if let street = street, !street.isEmpty {
            components.append(street)
        }
        components.append(city)
        components.append(state)
        components.append(postalCode)
        components.append(country)
        return components.joined(separator: ", ")
    }

    var shortAddress: String {
        return "\(city), \(state)"
    }
}

enum AddressVisibility: String, Codable, CaseIterable {
    case fullAddress = "Full Address"
    case cityOnly = "City Only"
    case hidden = "Hidden"

    var description: String {
        switch self {
        case .fullAddress:
            return "Show full address to group members"
        case .cityOnly:
            return "Show only city and state"
        case .hidden:
            return "Keep address private"
        }
    }
}

enum AuthMethod: String, Codable {
    case email = "Email"
    case phone = "Phone"
}

// MARK: - User Model

struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    var paypalId: String
    let createdAt: Date
    var profileImageURL: String?
    var isEmailVerified: Bool

    // Address fields
    var address: Address?
    var addressVisibility: AddressVisibility
    var countryCode: String?

    // Authentication fields
    var phoneNumber: String?
    var preferredAuthMethod: AuthMethod
    var biometricEnabled: Bool
    var lastLoginDate: Date?

    // MARK: - Initializers
    init(id: String = UUID().uuidString,
         name: String,
         email: String,
         paypalId: String,
         createdAt: Date = Date(),
         profileImageURL: String? = nil,
         isEmailVerified: Bool = false,
         address: Address? = nil,
         addressVisibility: AddressVisibility = .fullAddress,
         countryCode: String? = nil,
         phoneNumber: String? = nil,
         preferredAuthMethod: AuthMethod = .email,
         biometricEnabled: Bool = false,
         lastLoginDate: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.paypalId = paypalId
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.isEmailVerified = isEmailVerified
        self.address = address
        self.addressVisibility = addressVisibility
        self.countryCode = countryCode
        self.phoneNumber = phoneNumber
        self.preferredAuthMethod = preferredAuthMethod
        self.biometricEnabled = biometricEnabled
        self.lastLoginDate = lastLoginDate
    }
    
    // MARK: - Computed Properties
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }
    
    var displayName: String {
        return name.isEmpty ? email : name
    }
    
    var displayAddressForVisibility: String? {
        guard let address = address else { return nil }

        switch addressVisibility {
        case .fullAddress:
            return address.fullAddress
        case .cityOnly:
            return address.shortAddress
        case .hidden:
            return nil
        }
    }

    // MARK: - Equatable Implementation
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.paypalId == rhs.paypalId &&
               lhs.profileImageURL == rhs.profileImageURL &&
               lhs.isEmailVerified == rhs.isEmailVerified &&
               lhs.address == rhs.address &&
               lhs.phoneNumber == rhs.phoneNumber
        // Note: Excluding createdAt and lastLoginDate from comparison as they're time-based
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUsers: [User] = [
        User(name: "John Smith", email: "john@gmail.com", paypalId: "john.paypal@gmail.com", isEmailVerified: true),
        User(name: "Sarah Kumar", email: "sarah@gmail.com", paypalId: "sarah.paypal@gmail.com", isEmailVerified: true),
        User(name: "Mike Johnson", email: "mike@gmail.com", paypalId: "mike.paypal@gmail.com", isEmailVerified: true),
        User(name: "Lisa Chen", email: "lisa@gmail.com", paypalId: "lisa.paypal@gmail.com", isEmailVerified: false)
    ]
    
    static let currentUser = sampleUsers[0]
}
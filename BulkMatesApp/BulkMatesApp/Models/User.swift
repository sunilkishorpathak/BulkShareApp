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

struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    var paypalId: String
    let createdAt: Date
    var profileImageURL: String?
    var isEmailVerified: Bool
    
    // MARK: - Initializers
    init(id: String = UUID().uuidString, 
         name: String, 
         email: String, 
         paypalId: String, 
         createdAt: Date = Date(),
         profileImageURL: String? = nil,
         isEmailVerified: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.paypalId = paypalId
        self.createdAt = createdAt
        self.profileImageURL = profileImageURL
        self.isEmailVerified = isEmailVerified
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
    
    // MARK: - Equatable Implementation
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.paypalId == rhs.paypalId &&
               lhs.profileImageURL == rhs.profileImageURL &&
               lhs.isEmailVerified == rhs.isEmailVerified
        // Note: Excluding createdAt from comparison as it shouldn't change
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
//
//  Group.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  Group.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation

struct Group: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var members: [String] // User IDs
    var invitedEmails: [String] // Invited email addresses that haven't joined yet
    var icon: String
    let createdAt: Date
    var adminId: String
    var isActive: Bool
    
    // MARK: - Initializers
    init(id: String = UUID().uuidString,
         name: String,
         description: String = "",
         members: [String] = [],
         invitedEmails: [String] = [],
         icon: String = "👥",
         createdAt: Date = Date(),
         adminId: String,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.members = members
        self.invitedEmails = invitedEmails
        self.icon = icon
        self.createdAt = createdAt
        self.adminId = adminId
        self.isActive = isActive
    }
    
    // MARK: - Computed Properties
    var memberCount: Int {
        return members.count + invitedEmails.count
    }
    
    var isUserAdmin: Bool {
        return adminId == User.currentUser.id
    }
}

// MARK: - Sample Data
extension Group {
    static let sampleGroups: [Group] = [
        Group(
            name: "Sage Elite Family",
            description: "Family bulk shopping group for cost savings",
            members: ["user1", "user2", "user3", "user4"],
            invitedEmails: [],
            icon: "👨‍👩‍👧‍👦",
            adminId: "user1"
        ),
        Group(
            name: "Building 7 Neighbors",
            description: "Neighbors sharing bulk purchases from Costco",
            members: ["user1", "user5", "user6", "user7", "user8"],
            invitedEmails: [],
            icon: "🏢",
            adminId: "user5"
        ),
        Group(
            name: "Oak Street Community",
            description: "Community group for sustainable shopping",
            members: ["user9", "user10", "user11"],
            invitedEmails: [],
            icon: "🏘️",
            adminId: "user9"
        )
    ]
}
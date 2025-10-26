//
//  Activity.swift
//  BulkMatesApp
//
//  Plan-level activity feed models
//

import Foundation
import FirebaseFirestore

enum ActivityType: String, Codable {
    case comment = "comment"
    case photo = "photo"
    case receipt = "receipt"
    case location = "location"
    case systemActivity = "system_activity"
}

enum SystemActivityType: String, Codable {
    case itemAdded = "item_added"
    case itemClaimed = "item_claimed"
    case itemUpdated = "item_updated"
    case memberAdded = "member_added"
    case memberRemoved = "member_removed"
    case roleChanged = "role_changed"
    case planUpdated = "plan_updated"
}

struct PlanActivity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var tripId: String  // Trip ID this activity belongs to
    var userId: String
    var userName: String
    var userProfileImageURL: String?

    var type: ActivityType
    var message: String?  // Comment text or system message
    var imageURL: String?  // For photos/receipts
    var imageType: String?  // "photo" or "receipt"
    var location: String?  // Location text

    // For system activities
    var systemActivityType: SystemActivityType?
    var relatedItemId: String?  // For item-related activities
    var relatedItemName: String?
    var metadata: [String: String]?  // Additional data

    var timestamp: Date
    var likes: [String] = []  // User IDs who liked

    // Computed properties
    var likeCount: Int {
        likes.count
    }

    func isLikedByUser(_ userId: String) -> Bool {
        likes.contains(userId)
    }
}

struct ActivityReply: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userId: String
    var userName: String
    var userProfileImageURL: String?
    var message: String
    var timestamp: Date
}

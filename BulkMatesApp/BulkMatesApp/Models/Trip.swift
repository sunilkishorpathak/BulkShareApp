//
//  Trip.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  Trip.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation
import SwiftUI

// MARK: - Trip Type Enum
enum TripType: String, Codable, CaseIterable {
    case bulkShopping = "bulk_shopping"
    case eventPlanning = "event_planning"
    case groupTrip = "group_trip"
    case potluckMeal = "potluck_meal"

    var displayName: String {
        switch self {
        case .bulkShopping: return "Bulk Shopping"
        case .eventPlanning: return "Event Planning"
        case .groupTrip: return "Group Trip"
        case .potluckMeal: return "Potluck/Shared Meal"
        }
    }

    var icon: String {
        switch self {
        case .bulkShopping: return "🛒"
        case .eventPlanning: return "🎉"
        case .groupTrip: return "🏕️"
        case .potluckMeal: return "🍽️"
        }
    }

    var description: String {
        switch self {
        case .bulkShopping: return "Coordinate bulk purchases from wholesale stores"
        case .eventPlanning: return "Plan birthdays, parties, and festival events"
        case .groupTrip: return "Organize camping, picnics, and road trips"
        case .potluckMeal: return "Coordinate potlucks and shared meal contributions"
        }
    }

    var accentColor: Color {
        switch self {
        case .bulkShopping: return .bulkSharePrimary      // Green
        case .eventPlanning: return .bulkShareWarning     // Yellow/Gold
        case .groupTrip: return .bulkShareInfo            // Teal/Blue
        case .potluckMeal: return .orange                 // Orange
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .bulkShopping: return "No bulk shopping trips found"
        case .eventPlanning: return "No event planning trips found"
        case .groupTrip: return "No group trips found"
        case .potluckMeal: return "No potluck trips found"
        }
    }

    var emptyStateSubtitle: String {
        switch self {
        case .bulkShopping: return "Create a trip to Costco, Sam's Club, or BJ's"
        case .eventPlanning: return "Plan a birthday party, festival, or celebration"
        case .groupTrip: return "Organize a camping trip, picnic, or road trip"
        case .potluckMeal: return "Coordinate a potluck or shared meal event"
        }
    }
}

// MARK: - Trip Role Enum
enum TripRole: String, Codable, CaseIterable {
    case admin = "Admin"
    case viewer = "Viewer"
    case notMember = "Not a member"

    var icon: String {
        switch self {
        case .admin: return "🔧"
        case .viewer: return "👁️"
        case .notMember: return "❌"
        }
    }

    var displayName: String {
        return self.rawValue
    }

    var description: String {
        switch self {
        case .admin: return "Can edit and manage the trip"
        case .viewer: return "Can view and claim items"
        case .notMember: return "Not a member of this trip"
        }
    }

    var accentColor: Color {
        switch self {
        case .admin: return .bulkShareInfo
        case .viewer: return .bulkShareSuccess
        case .notMember: return .bulkShareTextLight
        }
    }
}

// MARK: - Trip Model
struct Trip: Identifiable, Codable {
    let id: String
    var groupId: String
    var shopperId: String
    var tripType: TripType // Type of trip (bulk shopping, event, group trip, potluck)
    var store: Store
    var scheduledDate: Date
    var items: [TripItem]
    var status: TripStatus
    let createdAt: Date
    var participants: [String] // User IDs who joined
    var notes: String?

    // MARK: - Role Management Properties
    var creatorId: String // User who created the trip
    var adminIds: [String] // Users with admin access
    var viewerIds: [String] // Users with viewer access

    // MARK: - Initializers
    init(id: String = UUID().uuidString,
         groupId: String,
         shopperId: String,
         tripType: TripType = .bulkShopping, // Default to bulk shopping for backward compatibility
         store: Store,
         scheduledDate: Date,
         items: [TripItem] = [],
         status: TripStatus = .planned,
         createdAt: Date = Date(),
         participants: [String] = [],
         notes: String? = nil,
         creatorId: String = "",
         adminIds: [String] = [],
         viewerIds: [String] = []) {
        self.id = id
        self.groupId = groupId
        self.shopperId = shopperId
        self.tripType = tripType
        self.store = store
        self.scheduledDate = scheduledDate
        self.items = items
        self.status = status
        self.createdAt = createdAt
        self.participants = participants
        self.notes = notes
        self.creatorId = creatorId
        self.adminIds = adminIds
        self.viewerIds = viewerIds
    }
    
    // MARK: - Computed Properties
    var isUpcoming: Bool {
        return scheduledDate > Date() && status == .planned
    }

    var participantCount: Int {
        return participants.count
    }

    var totalEstimatedCost: Double {
        return items.reduce(0) { total, item in
            total + (item.estimatedPrice * Double(item.quantityAvailable))
        }
    }

    // MARK: - Role Management Methods

    /// Get the role of a user in this trip
    func userRole(userId: String) -> TripRole {
        if adminIds.contains(userId) {
            return .admin
        } else if viewerIds.contains(userId) {
            return .viewer
        } else {
            return .notMember
        }
    }

    /// Check if user can edit the trip list (add/edit/delete items)
    func canEditList(userId: String) -> Bool {
        return adminIds.contains(userId)
    }

    /// Check if user is the trip creator
    func isCreator(userId: String) -> Bool {
        return creatorId == userId
    }

    /// Check if user is the last admin
    func isLastAdmin(userId: String) -> Bool {
        return adminIds.count == 1 && adminIds.contains(userId)
    }

    /// Promote a user to admin role
    mutating func promoteToAdmin(userId: String) {
        // Remove from viewers
        viewerIds.removeAll { $0 == userId }
        // Add to admins if not already there
        if !adminIds.contains(userId) {
            adminIds.append(userId)
        }
    }

    /// Demote a user to viewer role
    mutating func demoteToViewer(userId: String) {
        // Remove from admins
        adminIds.removeAll { $0 == userId }
        // Add to viewers if not already there
        if !viewerIds.contains(userId) {
            viewerIds.append(userId)
        }
    }

    /// Get all admin users
    var adminUserIds: [String] {
        return adminIds
    }

    /// Get all viewer users
    var viewerUserIds: [String] {
        return viewerIds
    }

    /// Get total member count (admins + viewers)
    var totalMemberCount: Int {
        return adminIds.count + viewerIds.count
    }
}

// MARK: - Supporting Models
struct TripItem: Identifiable, Codable {
    let id: String
    var name: String
    var quantityAvailable: Int // Total quantity needed/available
    var estimatedPrice: Double
    var category: ItemCategory
    var notes: String?
    var isCompleted: Bool // Track if item has been fulfilled/delivered

    init(id: String = UUID().uuidString,
         name: String,
         quantityAvailable: Int,
         estimatedPrice: Double,
         category: ItemCategory = .grocery,
         notes: String? = nil,
         isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.quantityAvailable = quantityAvailable
        self.estimatedPrice = estimatedPrice
        self.category = category
        self.notes = notes
        self.isCompleted = isCompleted
    }

    // MARK: - Computed Properties

    /// Alias for backward compatibility and clarity - represents total quantity needed
    var totalQuantity: Int {
        return quantityAvailable
    }

    /// Calculate claimed quantity from all active claims
    func claimedQuantity(claims: [ItemClaim]) -> Int {
        return claims
            .filter { $0.itemId == self.id && $0.status != .cancelled && $0.status != .rejected }
            .reduce(0) { $0 + $1.quantityClaimed }
    }

    /// Calculate remaining quantity after claims
    func remainingQuantity(claims: [ItemClaim]) -> Int {
        let claimed = claimedQuantity(claims: claims)
        return max(0, quantityAvailable - claimed)
    }

    /// Check if item is fully claimed
    func isFullyClaimed(claims: [ItemClaim]) -> Bool {
        return remainingQuantity(claims: claims) == 0
    }

    /// Check if item has any quantity available
    var isAvailable: Bool {
        return quantityAvailable > 0
    }
}

enum TripStatus: String, Codable, CaseIterable {
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .planned: return "4CAF50"
        case .inProgress: return "ff9800"
        case .completed: return "2196f3"
        case .cancelled: return "f44336"
        }
    }
}

enum Store: String, Codable, CaseIterable {
    case costco = "costco"
    case samsClub = "sams_club"
    case bjs = "bjs"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .costco: return "Costco"
        case .samsClub: return "Sam's Club"
        case .bjs: return "BJ's Wholesale"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .costco: return "🏪"
        case .samsClub: return "🏬"
        case .bjs: return "🏭"
        case .other: return "🛒"
        }
    }
}

enum ItemCategory: String, Codable, CaseIterable {
    // Bulk Shopping Categories
    case grocery = "grocery"
    case household = "household"
    case personal = "personal"
    case electronics = "electronics"
    case clothing = "clothing"

    // Event Planning Categories
    case decorations = "decorations"
    case entertainment = "entertainment"
    case partySupplies = "party_supplies"

    // Group Trip Categories
    case camping = "camping"
    case travel = "travel"
    case outdoor = "outdoor"

    // Potluck/Meal Categories
    case appetizers = "appetizers"
    case mainCourse = "main_course"
    case desserts = "desserts"
    case beverages = "beverages"
    case utensils = "utensils"

    // General
    case other = "other"

    var displayName: String {
        switch self {
        // Bulk Shopping
        case .grocery: return "Grocery"
        case .household: return "Household"
        case .personal: return "Personal Care"
        case .electronics: return "Electronics"
        case .clothing: return "Clothing"

        // Event Planning
        case .decorations: return "Decorations"
        case .entertainment: return "Entertainment"
        case .partySupplies: return "Party Supplies"

        // Group Trip
        case .camping: return "Camping Gear"
        case .travel: return "Travel Essentials"
        case .outdoor: return "Outdoor Equipment"

        // Potluck/Meal
        case .appetizers: return "Appetizers"
        case .mainCourse: return "Main Course"
        case .desserts: return "Desserts"
        case .beverages: return "Beverages"
        case .utensils: return "Utensils & Supplies"

        // General
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        // Bulk Shopping
        case .grocery: return "🥗"
        case .household: return "🧽"
        case .personal: return "🧴"
        case .electronics: return "📱"
        case .clothing: return "👕"

        // Event Planning
        case .decorations: return "🎈"
        case .entertainment: return "🎵"
        case .partySupplies: return "🎊"

        // Group Trip
        case .camping: return "⛺"
        case .travel: return "🧳"
        case .outdoor: return "🏔️"

        // Potluck/Meal
        case .appetizers: return "🥙"
        case .mainCourse: return "🍗"
        case .desserts: return "🍰"
        case .beverages: return "🥤"
        case .utensils: return "🍴"

        // General
        case .other: return "📦"
        }
    }

    /// Get relevant categories for a specific trip type
    static func categoriesFor(tripType: TripType) -> [ItemCategory] {
        switch tripType {
        case .bulkShopping:
            return [.grocery, .household, .personal, .electronics, .clothing, .other]
        case .eventPlanning:
            return [.decorations, .entertainment, .partySupplies, .grocery, .beverages, .other]
        case .groupTrip:
            return [.camping, .travel, .outdoor, .grocery, .beverages, .other]
        case .potluckMeal:
            return [.appetizers, .mainCourse, .desserts, .beverages, .utensils, .other]
        }
    }
}

// MARK: - Sample Data
extension Trip {
    static let sampleTrips: [Trip] = [
        // Bulk Shopping Trip
        Trip(
            groupId: "group1",
            shopperId: "user2",
            tripType: .bulkShopping,
            store: .costco,
            scheduledDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
            items: [
                TripItem(name: "Kirkland Bread (2-pack)", quantityAvailable: 1, estimatedPrice: 4.50, category: .grocery),
                TripItem(name: "Organic Eggs (24 count)", quantityAvailable: 2, estimatedPrice: 6.99, category: .grocery),
                TripItem(name: "Paper Towels (12-pack)", quantityAvailable: 1, estimatedPrice: 18.99, category: .household)
            ],
            participants: ["user1", "user3"]
        ),
        Trip(
            groupId: "group1",
            shopperId: "user3",
            tripType: .bulkShopping,
            store: .samsClub,
            scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            items: [
                TripItem(name: "Rotisserie Chicken", quantityAvailable: 1, estimatedPrice: 4.98, category: .grocery),
                TripItem(name: "Bananas (3 lbs)", quantityAvailable: 2, estimatedPrice: 1.98, category: .grocery)
            ],
            participants: ["user1"]
        ),
        // Potluck Event
        Trip(
            groupId: "group2",
            shopperId: "user1",
            tripType: .potluckMeal,
            store: .other,
            scheduledDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            items: [
                TripItem(name: "Popsicles", quantityAvailable: 40, estimatedPrice: 0.50, category: .desserts, notes: "For 40 people"),
                TripItem(name: "Burger Patties", quantityAvailable: 30, estimatedPrice: 2.00, category: .mainCourse),
                TripItem(name: "Paper Plates & Cups", quantityAvailable: 50, estimatedPrice: 0.20, category: .utensils)
            ],
            participants: ["user2", "user4", "user5"],
            notes: "Summer BBQ Potluck - Everyone brings something!"
        ),
        // Birthday Party
        Trip(
            groupId: "group3",
            shopperId: "user4",
            tripType: .eventPlanning,
            store: .other,
            scheduledDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            items: [
                TripItem(name: "Balloons", quantityAvailable: 50, estimatedPrice: 0.30, category: .decorations),
                TripItem(name: "Birthday Cake", quantityAvailable: 1, estimatedPrice: 45.00, category: .desserts),
                TripItem(name: "Party Hats", quantityAvailable: 20, estimatedPrice: 1.50, category: .partySupplies)
            ],
            participants: ["user1", "user2"],
            notes: "Sarah's 10th Birthday Party"
        )
    ]
}
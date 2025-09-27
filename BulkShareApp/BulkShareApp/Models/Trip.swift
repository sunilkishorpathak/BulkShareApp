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

struct Trip: Identifiable, Codable {
    let id: String
    var groupId: String
    var shopperId: String
    var store: Store
    var scheduledDate: Date
    var items: [TripItem]
    var status: TripStatus
    let createdAt: Date
    var participants: [String] // User IDs who joined
    var notes: String?
    
    // MARK: - Initializers
    init(id: String = UUID().uuidString,
         groupId: String,
         shopperId: String,
         store: Store,
         scheduledDate: Date,
         items: [TripItem] = [],
         status: TripStatus = .planned,
         createdAt: Date = Date(),
         participants: [String] = [],
         notes: String? = nil) {
        self.id = id
        self.groupId = groupId
        self.shopperId = shopperId
        self.store = store
        self.scheduledDate = scheduledDate
        self.items = items
        self.status = status
        self.createdAt = createdAt
        self.participants = participants
        self.notes = notes
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
}

// MARK: - Supporting Models
struct TripItem: Identifiable, Codable {
    let id: String
    var name: String
    var quantityAvailable: Int
    var estimatedPrice: Double
    var category: ItemCategory
    var notes: String?
    
    init(id: String = UUID().uuidString,
         name: String,
         quantityAvailable: Int,
         estimatedPrice: Double,
         category: ItemCategory = .grocery,
         notes: String? = nil) {
        self.id = id
        self.name = name
        self.quantityAvailable = quantityAvailable
        self.estimatedPrice = estimatedPrice
        self.category = category
        self.notes = notes
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
    case grocery = "grocery"
    case household = "household"
    case personal = "personal"
    case electronics = "electronics"
    case clothing = "clothing"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .grocery: return "Grocery"
        case .household: return "Household"
        case .personal: return "Personal Care"
        case .electronics: return "Electronics"
        case .clothing: return "Clothing"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .grocery: return "🥗"
        case .household: return "🧽"
        case .personal: return "🧴"
        case .electronics: return "📱"
        case .clothing: return "👕"
        case .other: return "📦"
        }
    }
}

// MARK: - Sample Data
extension Trip {
    static let sampleTrips: [Trip] = [
        Trip(
            groupId: "group1",
            shopperId: "user2",
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
            store: .samsClub,
            scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            items: [
                TripItem(name: "Rotisserie Chicken", quantityAvailable: 1, estimatedPrice: 4.98, category: .grocery),
                TripItem(name: "Bananas (3 lbs)", quantityAvailable: 2, estimatedPrice: 1.98, category: .grocery)
            ],
            participants: ["user1"]
        )
    ]
}
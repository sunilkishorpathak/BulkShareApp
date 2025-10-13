//
//  ItemDelivery.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import Foundation

struct ItemDelivery: Identifiable, Codable {
    let id: String
    let tripId: String
    let claimId: String
    let itemId: String
    let receiverUserId: String
    let delivererUserId: String  // Person who delivered (shopper or another member)
    var isDelivered: Bool
    var deliveredAt: Date?
    var confirmationNote: String?
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         tripId: String,
         claimId: String,
         itemId: String,
         receiverUserId: String,
         delivererUserId: String,
         isDelivered: Bool = false,
         deliveredAt: Date? = nil,
         confirmationNote: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.claimId = claimId
        self.itemId = itemId
        self.receiverUserId = receiverUserId
        self.delivererUserId = delivererUserId
        self.isDelivered = isDelivered
        self.deliveredAt = deliveredAt
        self.confirmationNote = confirmationNote
        self.createdAt = createdAt
    }
    
    // Helper to create delivery records from accepted claims
    static func createFromClaim(_ claim: ItemClaim, delivererUserId: String) -> ItemDelivery {
        return ItemDelivery(
            tripId: claim.tripId,
            claimId: claim.id,
            itemId: claim.itemId,
            receiverUserId: claim.claimerUserId,
            delivererUserId: delivererUserId
        )
    }
}

enum DeliveryStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case delivered = "delivered"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Delivery"
        case .delivered: return "Delivered"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .delivered: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .delivered: return "checkmark.circle.fill"
        }
    }
}
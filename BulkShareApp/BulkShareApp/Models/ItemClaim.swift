//
//  ItemClaim.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation

struct ItemClaim: Identifiable, Codable {
    let id: String
    let tripId: String
    let itemId: String
    let claimerUserId: String
    let quantityClaimed: Int
    let claimedAt: Date
    var status: ClaimStatus
    
    init(id: String = UUID().uuidString,
         tripId: String,
         itemId: String,
         claimerUserId: String,
         quantityClaimed: Int,
         claimedAt: Date = Date(),
         status: ClaimStatus = .pending) {
        self.id = id
        self.tripId = tripId
        self.itemId = itemId
        self.claimerUserId = claimerUserId
        self.quantityClaimed = quantityClaimed
        self.claimedAt = claimedAt
        self.status = status
    }
}

enum ClaimStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .cancelled: return "Cancelled"
        }
    }
}
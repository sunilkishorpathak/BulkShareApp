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
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Approval"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "green"
        case .rejected: return "red"
        case .cancelled: return "gray"
        }
    }
}
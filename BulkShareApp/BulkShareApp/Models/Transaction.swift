//
//  Transaction.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation

struct Transaction: Identifiable, Codable {
    let id: String
    let tripId: String
    let fromUserId: String // Person who owes money (buyer)
    let toUserId: String   // Person who should receive money (shopper)
    let amount: Double
    let itemClaimIds: [String] // Claims this transaction covers
    let createdAt: Date
    var status: TransactionStatus
    var paidAt: Date?
    var notes: String?
    
    init(id: String = UUID().uuidString,
         tripId: String,
         fromUserId: String,
         toUserId: String,
         amount: Double,
         itemClaimIds: [String],
         createdAt: Date = Date(),
         status: TransactionStatus = .pending,
         paidAt: Date? = nil,
         notes: String? = nil) {
        self.id = id
        self.tripId = tripId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.amount = amount
        self.itemClaimIds = itemClaimIds
        self.createdAt = createdAt
        self.status = status
        self.paidAt = paidAt
        self.notes = notes
    }
    
    var isOutstanding: Bool {
        return status == .pending
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case paid = "paid"
    case disputed = "disputed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .paid: return "Paid"
        case .disputed: return "Disputed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "FF9800"
        case .paid: return "4CAF50"
        case .disputed: return "F44336"
        case .cancelled: return "9E9E9E"
        }
    }
}

// MARK: - User Balance Summary
struct UserBalance: Identifiable, Codable {
    let id: String
    let userId: String
    var totalOwed: Double    // Money this user owes to others
    var totalOwedTo: Double  // Money others owe to this user
    let lastUpdated: Date
    
    var netBalance: Double {
        return totalOwedTo - totalOwed
    }
    
    var balanceDescription: String {
        let amount = abs(netBalance)
        if netBalance > 0 {
            return "You are owed $\(String(format: "%.2f", amount))"
        } else if netBalance < 0 {
            return "You owe $\(String(format: "%.2f", amount))"
        } else {
            return "All settled up!"
        }
    }
}
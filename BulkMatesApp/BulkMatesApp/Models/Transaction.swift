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
    let fromUserId: String // Person who owes items (recipient)
    let toUserId: String   // Person who provided items (shopper)
    let itemPoints: Int    // Number of items involved in this transaction
    let itemClaimIds: [String] // Claims this transaction covers
    let createdAt: Date
    var status: TransactionStatus
    var settledAt: Date?
    var notes: String?
    
    init(id: String = UUID().uuidString,
         tripId: String,
         fromUserId: String,
         toUserId: String,
         itemPoints: Int,
         itemClaimIds: [String],
         createdAt: Date = Date(),
         status: TransactionStatus = .pending,
         settledAt: Date? = nil,
         notes: String? = nil) {
        self.id = id
        self.tripId = tripId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.itemPoints = itemPoints
        self.itemClaimIds = itemClaimIds
        self.createdAt = createdAt
        self.status = status
        self.settledAt = settledAt
        self.notes = notes
    }
    
    var isOutstanding: Bool {
        return status == .pending
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case settled = "settled"
    case disputed = "disputed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .settled: return "Settled"
        case .disputed: return "Disputed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "FF9800"
        case .settled: return "4CAF50"
        case .disputed: return "F44336"
        case .cancelled: return "9E9E9E"
        }
    }
}

// MARK: - User Balance Summary
struct UserBalance: Identifiable, Codable {
    let id: String
    let userId: String
    var totalItemsOwed: Int      // Items this user owes to others (negative balance)
    var totalItemsOwedTo: Int    // Items others owe to this user (positive balance)
    let lastUpdated: Date
    
    var netItemBalance: Int {
        return totalItemsOwedTo - totalItemsOwed
    }
    
    var balanceDescription: String {
        let itemCount = abs(netItemBalance)
        if netItemBalance > 0 {
            return "Others owe you \(itemCount) item\(itemCount == 1 ? "" : "s")"
        } else if netItemBalance < 0 {
            return "You owe others \(itemCount) item\(itemCount == 1 ? "" : "s")"
        } else {
            return "All settled up!"
        }
    }
}
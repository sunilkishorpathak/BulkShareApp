//
//  ItemRequest.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation

struct ItemRequest: Identifiable, Codable {
    let id: String
    let tripId: String
    let requesterUserId: String
    let itemName: String
    let quantityRequested: Int
    let category: ItemCategory
    let notes: String?
    let requestedAt: Date
    var status: ItemRequestStatus
    
    init(id: String = UUID().uuidString,
         tripId: String,
         requesterUserId: String,
         itemName: String,
         quantityRequested: Int,
         category: ItemCategory,
         notes: String? = nil,
         requestedAt: Date = Date(),
         status: ItemRequestStatus = .pending) {
        self.id = id
        self.tripId = tripId
        self.requesterUserId = requesterUserId
        self.itemName = itemName
        self.quantityRequested = quantityRequested
        self.category = category
        self.notes = notes
        self.requestedAt = requestedAt
        self.status = status
    }
}

enum ItemRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Approval"
        case .approved: return "Approved & Added"
        case .rejected: return "Rejected"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        }
    }
}
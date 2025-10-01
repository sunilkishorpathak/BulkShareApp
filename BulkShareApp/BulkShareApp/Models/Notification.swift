//
//  Notification.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation

struct Notification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let recipientUserId: String
    let senderUserId: String
    let senderName: String
    let relatedId: String // groupId, tripId, etc.
    let createdAt: Date
    var isRead: Bool
    var status: NotificationStatus
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        message: String,
        recipientUserId: String,
        senderUserId: String,
        senderName: String,
        relatedId: String,
        createdAt: Date = Date(),
        isRead: Bool = false,
        status: NotificationStatus = .pending
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.recipientUserId = recipientUserId
        self.senderUserId = senderUserId
        self.senderName = senderName
        self.relatedId = relatedId
        self.createdAt = createdAt
        self.isRead = isRead
        self.status = status
    }
}

enum NotificationType: String, CaseIterable, Codable {
    case groupInvitation = "group_invitation"
    case tripInvitation = "trip_invitation"
    case tripUpdate = "trip_update"
    case groupUpdate = "group_update"
    
    var icon: String {
        switch self {
        case .groupInvitation:
            return "person.badge.plus"
        case .tripInvitation:
            return "cart.badge.plus"
        case .tripUpdate:
            return "cart"
        case .groupUpdate:
            return "person.3"
        }
    }
    
    var color: String {
        switch self {
        case .groupInvitation:
            return "bulkSharePrimary"
        case .tripInvitation:
            return "bulkShareInfo"
        case .tripUpdate:
            return "bulkShareWarning"
        case .groupUpdate:
            return "bulkShareSuccess"
        }
    }
}

enum NotificationStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        case .expired:
            return "Expired"
        }
    }
}

// MARK: - Sample Data

extension Notification {
    static let sampleNotifications: [Notification] = [
        Notification(
            type: .groupInvitation,
            title: "Group Invitation",
            message: "Sarah invited you to join 'Family Shopping Group'",
            recipientUserId: "user1",
            senderUserId: "user2",
            senderName: "Sarah Kumar",
            relatedId: "group123"
        ),
        Notification(
            type: .tripInvitation,
            title: "Trip Invitation",
            message: "John invited you to join the Costco trip on Saturday",
            recipientUserId: "user1",
            senderUserId: "user3",
            senderName: "John Smith",
            relatedId: "trip456"
        ),
        Notification(
            type: .tripUpdate,
            title: "Trip Update",
            message: "The Costco trip has been rescheduled to Sunday",
            recipientUserId: "user1",
            senderUserId: "user3",
            senderName: "John Smith",
            relatedId: "trip456"
        )
    ]
}
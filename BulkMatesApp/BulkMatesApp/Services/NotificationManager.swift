//
//  NotificationManager.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation
import Firebase
import FirebaseFirestore

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    
    private let firestore = Firestore.firestore()
    private var notificationListener: ListenerRegistration?
    
    init() {
        // Start listening for notifications when user is authenticated
    }
    
    // MARK: - Public Methods
    
    func startListening(for userId: String) {
        print("🎧 NotificationManager: Starting listener for userId: \(userId)")
        stopListening()
        
        notificationListener = firestore.collection("notifications")
            .whereField("recipientUserId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching notifications: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                print("📬 Received \(documents.count) notification documents for user \(userId)")
                let notifications = documents.compactMap { self?.parseNotification(from: $0) }
                print("📋 Parsed \(notifications.count) valid notifications")
                
                DispatchQueue.main.async {
                    self?.notifications = notifications
                    self?.updateUnreadCount()
                    print("🔄 Updated notifications list with \(notifications.count) items")
                }
            }
    }
    
    func stopListening() {
        notificationListener?.remove()
        notificationListener = nil
    }
    
    func createTripNotification(
        tripId: String,
        trip: Trip,
        creatorUserId: String,
        creatorName: String,
        groupMembers: [String]
    ) async throws {
        // Get creator's profile image URL
        let creatorProfileImageURL = try? await FirebaseManager.shared.getUser(uid: creatorUserId).profileImageURL

        // Send notification to all group members except the creator
        let recipients = groupMembers.filter { $0 != creatorUserId }

        for recipientUserId in recipients {
            let notification = Notification(
                type: .tripInvitation,
                title: "New Shopping Trip",
                message: "\(creatorName) created a trip to \(trip.store.displayName) with \(trip.items.count) items available",
                recipientUserId: recipientUserId,
                senderUserId: creatorUserId,
                senderName: creatorName,
                senderProfileImageURL: creatorProfileImageURL,
                relatedId: tripId
            )

            try await saveNotification(notification)
        }
    }
    
    func createGroupInvitationNotification(
        groupId: String,
        groupName: String,
        inviterUserId: String,
        inviterName: String,
        recipientEmail: String
    ) async throws {
        print("🔍 Looking for user with email: \(recipientEmail)")

        // Get inviter's profile image URL
        let inviterProfileImageURL = try? await FirebaseManager.shared.getUser(uid: inviterUserId).profileImageURL

        // First, find the user by email (if they exist)
        let userSnapshot = try await firestore.collection("users")
            .whereField("email", isEqualTo: recipientEmail)
            .getDocuments()

        print("📊 Found \(userSnapshot.documents.count) users with email \(recipientEmail)")

        guard let userDocument = userSnapshot.documents.first else {
            // User doesn't exist yet, they'll get the notification when they sign up
            print("❌ User with email \(recipientEmail) not found - notification will be created when they sign up")
            return
        }

        let recipientUserId = userDocument.documentID
        print("✅ Found user \(recipientUserId) for email \(recipientEmail)")

        let notification = Notification(
            type: .groupInvitation,
            title: "Group Invitation",
            message: "\(inviterName) invited you to join '\(groupName)'",
            recipientUserId: recipientUserId,
            senderUserId: inviterUserId,
            senderName: inviterName,
            senderProfileImageURL: inviterProfileImageURL,
            relatedId: groupId
        )

        try await saveNotification(notification)
        print("🔔 Group invitation notification created for user \(recipientUserId)")
    }
    
    func createClaimNotification(
        tripId: String,
        tripOrganizerId: String,
        claimerUserId: String,
        claimerName: String,
        itemsCount: Int,
        tripStore: String
    ) async throws {
        // Get claimer's profile image URL
        let claimerProfileImageURL = try? await FirebaseManager.shared.getUser(uid: claimerUserId).profileImageURL

        let notification = Notification(
            type: .tripUpdate,
            title: "Item Request Received",
            message: "\(claimerName) requested \(itemsCount) items from your \(tripStore) trip",
            recipientUserId: tripOrganizerId,
            senderUserId: claimerUserId,
            senderName: claimerName,
            senderProfileImageURL: claimerProfileImageURL,
            relatedId: tripId
        )

        try await saveNotification(notification)
        print("🔔 Claim notification created for trip organizer \(tripOrganizerId)")
    }
    
    func createItemRequestNotification(
        tripId: String,
        tripOrganizerId: String,
        requesterUserId: String,
        requesterName: String,
        itemName: String,
        quantity: Int
    ) async throws {
        // Get requester's profile image URL
        let requesterProfileImageURL = try? await FirebaseManager.shared.getUser(uid: requesterUserId).profileImageURL

        let notification = Notification(
            type: .tripUpdate,
            title: "New Item Request",
            message: "\(requesterName) requested \(quantity) x \(itemName) to be added to your trip",
            recipientUserId: tripOrganizerId,
            senderUserId: requesterUserId,
            senderName: requesterName,
            senderProfileImageURL: requesterProfileImageURL,
            relatedId: tripId
        )

        try await saveNotification(notification)
        print("🔔 Item request notification created for trip organizer \(tripOrganizerId)")
    }

    func createItemApprovalNotification(
        tripId: String,
        requesterUserId: String,
        organizerUserId: String,
        organizerName: String,
        itemName: String,
        quantity: Int
    ) async throws {
        // Get organizer's profile image URL
        let organizerProfileImageURL = try? await FirebaseManager.shared.getUser(uid: organizerUserId).profileImageURL

        let notification = Notification(
            type: .tripUpdate,
            title: "Item Request Approved!",
            message: "\(organizerName) approved your request for \(quantity) x \(itemName). It's now available in the trip!",
            recipientUserId: requesterUserId,
            senderUserId: organizerUserId,
            senderName: organizerName,
            senderProfileImageURL: organizerProfileImageURL,
            relatedId: tripId
        )

        try await saveNotification(notification)
        print("🔔 Item approval notification created for requester \(requesterUserId)")
    }
    
    func respondToGroupInvitation(
        notificationId: String,
        response: NotificationStatus,
        groupId: String,
        userId: String
    ) async throws {
        let batch = firestore.batch()
        
        // Update notification status
        let notificationRef = firestore.collection("notifications").document(notificationId)
        batch.updateData(["status": response.rawValue], forDocument: notificationRef)
        
        if response == .accepted {
            // Add user to group members
            let groupRef = firestore.collection("groups").document(groupId)
            batch.updateData([
                "members": FieldValue.arrayUnion([userId])
            ], forDocument: groupRef)
            
            // Remove user email from invitedEmails if it exists
            if let user = FirebaseManager.shared.currentUser {
                batch.updateData([
                    "invitedEmails": FieldValue.arrayRemove([user.email])
                ], forDocument: groupRef)
            }
        }
        
        try await batch.commit()
    }
    
    func markAsRead(_ notificationId: String) async throws {
        try await firestore.collection("notifications").document(notificationId)
            .updateData(["isRead": true])
    }
    
    func markAllAsRead(for userId: String) async throws {
        let snapshot = try await firestore.collection("notifications")
            .whereField("recipientUserId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = firestore.batch()
        
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Private Methods
    
    private func saveNotification(_ notification: Notification) async throws {
        var notificationData: [String: Any] = [
            "id": notification.id,
            "type": notification.type.rawValue,
            "title": notification.title,
            "message": notification.message,
            "recipientUserId": notification.recipientUserId,
            "senderUserId": notification.senderUserId,
            "senderName": notification.senderName,
            "relatedId": notification.relatedId,
            "createdAt": notification.createdAt,
            "isRead": notification.isRead,
            "status": notification.status.rawValue
        ]

        // Include sender profile image URL if available
        if let profileImageURL = notification.senderProfileImageURL {
            notificationData["senderProfileImageURL"] = profileImageURL
        }

        try await firestore.collection("notifications")
            .document(notification.id)
            .setData(notificationData)
    }
    
    private func parseNotification(from document: QueryDocumentSnapshot) -> Notification? {
        let data = document.data()

        guard let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let title = data["title"] as? String,
              let message = data["message"] as? String,
              let recipientUserId = data["recipientUserId"] as? String,
              let senderUserId = data["senderUserId"] as? String,
              let senderName = data["senderName"] as? String,
              let relatedId = data["relatedId"] as? String else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let isRead = data["isRead"] as? Bool ?? false
        let statusString = data["status"] as? String ?? "pending"
        let status = NotificationStatus(rawValue: statusString) ?? .pending
        let senderProfileImageURL = data["senderProfileImageURL"] as? String

        return Notification(
            id: document.documentID,
            type: type,
            title: title,
            message: message,
            recipientUserId: recipientUserId,
            senderUserId: senderUserId,
            senderName: senderName,
            senderProfileImageURL: senderProfileImageURL,
            relatedId: relatedId,
            createdAt: createdAt,
            isRead: isRead,
            status: status
        )
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
}
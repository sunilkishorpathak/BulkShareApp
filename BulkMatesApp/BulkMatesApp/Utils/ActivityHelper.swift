//
//  ActivityHelper.swift
//  BulkMatesApp
//
//  Helper for creating and managing system activities
//

import Foundation
import FirebaseFirestore

class ActivityHelper {
    static let shared = ActivityHelper()

    private init() {}

    // MARK: - Create System Activities

    /// Create an activity when an item is added to a trip
    func logItemAdded(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        item: TripItem
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "added \(item.name) to the plan",
            systemActivityType: .itemAdded,
            relatedItemId: item.id,
            relatedItemName: item.name,
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    /// Create an activity when an item is claimed
    func logItemClaimed(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        item: TripItem,
        quantity: Int
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "claimed \(quantity) of \(item.name)",
            systemActivityType: .itemClaimed,
            relatedItemId: item.id,
            relatedItemName: item.name,
            metadata: ["quantity": "\(quantity)"],
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    /// Create an activity when an item is updated
    func logItemUpdated(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        item: TripItem,
        changes: String
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "updated \(item.name) - \(changes)",
            systemActivityType: .itemUpdated,
            relatedItemId: item.id,
            relatedItemName: item.name,
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    /// Create an activity when a member is added to the trip
    func logMemberAdded(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        addedUserName: String
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "added \(addedUserName) to the plan",
            systemActivityType: .memberAdded,
            metadata: ["addedUserName": addedUserName],
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    /// Create an activity when a member is removed from the trip
    func logMemberRemoved(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        removedUserName: String
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "removed \(removedUserName) from the plan",
            systemActivityType: .memberRemoved,
            metadata: ["removedUserName": removedUserName],
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    /// Create an activity when a member's role is changed
    func logRoleChanged(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        targetUserName: String,
        newRole: TripRole
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "changed \(targetUserName)'s role to \(newRole.rawValue)",
            systemActivityType: .roleChanged,
            metadata: ["targetUserName": targetUserName, "newRole": newRole.rawValue],
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    /// Create an activity when the trip is updated
    func logTripUpdated(
        tripId: String,
        userId: String,
        userName: String,
        userProfileImageURL: String?,
        changes: String
    ) {
        let activity = PlanActivity(
            tripId: tripId,
            userId: userId,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            type: .systemActivity,
            message: "updated the plan - \(changes)",
            systemActivityType: .planUpdated,
            timestamp: Date()
        )

        saveActivity(activity, tripId: tripId)
    }

    // MARK: - Save Activity

    private func saveActivity(_ activity: PlanActivity, tripId: String) {
        let db = Firestore.firestore()

        do {
            let activityData = try Firestore.Encoder().encode(activity)

            db.collection("trips").document(tripId)
                .collection("activities")
                .document(activity.id)
                .setData(activityData) { error in
                    if let error = error {
                        print("❌ Error saving activity: \(error)")
                    } else {
                        // Update trip's activity count and timestamp
                        db.collection("trips").document(tripId).updateData([
                            "activityCount": FieldValue.increment(Int64(1)),
                            "lastActivityTimestamp": Timestamp(date: Date())
                        ])

                        print("✅ Activity logged: \(activity.message ?? "No message")")
                    }
                }
        } catch {
            print("❌ Error encoding activity: \(error)")
        }
    }
}

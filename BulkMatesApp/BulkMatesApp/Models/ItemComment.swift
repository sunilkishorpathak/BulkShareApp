//
//  ItemComment.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import Foundation

struct ItemComment: Identifiable, Codable {
    let id: String
    let tripId: String
    let itemId: String
    let userId: String
    let text: String
    let createdAt: Date

    init(id: String = UUID().uuidString,
         tripId: String,
         itemId: String,
         userId: String,
         text: String,
         createdAt: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.itemId = itemId
        self.userId = userId
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Sample Data
extension ItemComment {
    static let sampleComments: [ItemComment] = [
        ItemComment(
            tripId: "trip1",
            itemId: "item1",
            userId: "user1",
            text: "I can get bread from Trader Joe's instead of Costco if that's easier",
            createdAt: Date().addingTimeInterval(-3600)
        ),
        ItemComment(
            tripId: "trip1",
            itemId: "item1",
            userId: "user2",
            text: "Prefer wheat bread over white please!",
            createdAt: Date().addingTimeInterval(-1800)
        ),
        ItemComment(
            tripId: "trip1",
            itemId: "item1",
            userId: "user3",
            text: "Running a bit late, can someone else grab this?",
            createdAt: Date().addingTimeInterval(-300)
        )
    ]
}

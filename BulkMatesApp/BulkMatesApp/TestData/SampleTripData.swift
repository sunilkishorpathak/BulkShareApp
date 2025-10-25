//
//  SampleTripData.swift
//  BulkMatesApp
//
//  Test data for different trip types and partial claiming scenarios
//

import Foundation

extension Trip {
    // MARK: - Test Data for Different Trip Types

    static let testBulkShoppingTrip = Trip(
        id: "test-bulk-1",
        groupId: "test-group-1",
        shopperId: "test-user-1",
        tripType: .bulkShopping,
        store: .costco,
        scheduledDate: Date().addingTimeInterval(86400), // Tomorrow
        items: [
            TripItem(
                id: "item-bulk-1",
                name: "Kirkland Paper Towels (12-pack)",
                quantityAvailable: 2,
                estimatedPrice: 18.99,
                category: .household,
                notes: "Great deal on bulk paper products"
            ),
            TripItem(
                id: "item-bulk-2",
                name: "Organic Eggs (24 count)",
                quantityAvailable: 4,
                estimatedPrice: 6.99,
                category: .grocery
            ),
            TripItem(
                id: "item-bulk-3",
                name: "Rotisserie Chicken",
                quantityAvailable: 3,
                estimatedPrice: 4.99,
                category: .grocery,
                notes: "Hot and ready at 3pm"
            )
        ],
        status: .planned,
        participants: ["test-user-2", "test-user-3"],
        notes: "Saturday morning Costco run"
    )

    static let testEventPlanningTrip = Trip(
        id: "test-event-1",
        groupId: "test-group-2",
        shopperId: "test-user-2",
        tripType: .eventPlanning,
        store: .other,
        scheduledDate: Date().addingTimeInterval(604800), // 1 week
        items: [
            TripItem(
                id: "item-event-1",
                name: "Birthday Cake",
                quantityAvailable: 1,
                estimatedPrice: 45.00,
                category: .desserts,
                notes: "Chocolate with vanilla frosting"
            ),
            TripItem(
                id: "item-event-2",
                name: "Balloons (50 count)",
                quantityAvailable: 50,
                estimatedPrice: 0.30,
                category: .decorations
            ),
            TripItem(
                id: "item-event-3",
                name: "Party Hats",
                quantityAvailable: 20,
                estimatedPrice: 1.50,
                category: .partySupplies
            ),
            TripItem(
                id: "item-event-4",
                name: "Paper Plates & Cups",
                quantityAvailable: 30,
                estimatedPrice: 0.50,
                category: .utensils
            )
        ],
        status: .planned,
        participants: ["test-user-1", "test-user-3", "test-user-4"],
        notes: "Emma's 10th Birthday Party 🎉"
    )

    static let testPotluckTrip = Trip(
        id: "test-potluck-1",
        groupId: "test-group-3",
        shopperId: "test-user-3",
        tripType: .potluckMeal,
        store: .other,
        scheduledDate: Date().addingTimeInterval(259200), // 3 days
        items: [
            TripItem(
                id: "item-potluck-1",
                name: "Popsicles (Box of 40)",
                quantityAvailable: 40,
                estimatedPrice: 0.50,
                category: .desserts,
                notes: "Keep frozen until event! Various flavors."
            ),
            TripItem(
                id: "item-potluck-2",
                name: "Burger Patties",
                quantityAvailable: 30,
                estimatedPrice: 2.00,
                category: .mainCourse,
                notes: "80/20 beef blend"
            ),
            TripItem(
                id: "item-potluck-3",
                name: "Hot Dog Buns",
                quantityAvailable: 50,
                estimatedPrice: 0.30,
                category: .grocery
            ),
            TripItem(
                id: "item-potluck-4",
                name: "Sodas (Cans)",
                quantityAvailable: 48,
                estimatedPrice: 0.50,
                category: .beverages,
                notes: "Assorted - Coke, Sprite, Fanta"
            ),
            TripItem(
                id: "item-potluck-5",
                name: "Chips & Dip",
                quantityAvailable: 20,
                estimatedPrice: 1.50,
                category: .appetizers
            )
        ],
        status: .planned,
        participants: ["test-user-1", "test-user-2", "test-user-4", "test-user-5"],
        notes: "Summer BBQ Potluck 🍔🌭 - Everyone brings something!"
    )

    static let testGroupTrip = Trip(
        id: "test-group-trip-1",
        groupId: "test-group-4",
        shopperId: "test-user-4",
        tripType: .groupTrip,
        store: .other,
        scheduledDate: Date().addingTimeInterval(1209600), // 2 weeks
        items: [
            TripItem(
                id: "item-camping-1",
                name: "Tent (4-person)",
                quantityAvailable: 2,
                estimatedPrice: 150.00,
                category: .camping,
                notes: "Weather-resistant, easy setup"
            ),
            TripItem(
                id: "item-camping-2",
                name: "Sleeping Bags",
                quantityAvailable: 8,
                estimatedPrice: 40.00,
                category: .camping
            ),
            TripItem(
                id: "item-camping-3",
                name: "Camping Stove",
                quantityAvailable: 1,
                estimatedPrice: 80.00,
                category: .outdoor,
                notes: "Propane-powered, 2 burners"
            ),
            TripItem(
                id: "item-camping-4",
                name: "Firewood Bundle",
                quantityAvailable: 10,
                estimatedPrice: 8.00,
                category: .outdoor
            ),
            TripItem(
                id: "item-camping-5",
                name: "Cooler",
                quantityAvailable: 2,
                estimatedPrice: 60.00,
                category: .outdoor,
                notes: "Large capacity for food storage"
            )
        ],
        status: .planned,
        participants: ["test-user-1", "test-user-2", "test-user-3", "test-user-5"],
        notes: "Weekend camping trip to Yosemite 🏕️"
    )

    // MARK: - Test Scenarios for Partial Claiming

    // Scenario: Multiple users claiming same item
    static let partialClaimingTestTrip = Trip(
        id: "test-partial-1",
        groupId: "test-group-5",
        shopperId: "test-user-1",
        tripType: .potluckMeal,
        store: .other,
        scheduledDate: Date().addingTimeInterval(172800), // 2 days
        items: [
            TripItem(
                id: "item-partial-1",
                name: "Popsicles (Total: 40 needed)",
                quantityAvailable: 40,
                estimatedPrice: 0.50,
                category: .desserts,
                notes: "Test item for partial claiming - multiple users"
            )
        ],
        status: .planned,
        participants: ["test-user-2", "test-user-3", "test-user-4"],
        notes: "Test trip for partial claiming scenarios"
    )

    // Test claims for partial claiming scenario
    static let partialClaimingTestClaims = [
        ItemClaim(
            id: "claim-1",
            tripId: "test-partial-1",
            itemId: "item-partial-1",
            claimerUserId: "test-user-2",
            quantityClaimed: 15,
            claimedAt: Date().addingTimeInterval(-7200), // 2 hours ago
            status: .accepted,
            isCompleted: false
        ),
        ItemClaim(
            id: "claim-2",
            tripId: "test-partial-1",
            itemId: "item-partial-1",
            claimerUserId: "test-user-3",
            quantityClaimed: 10,
            claimedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            status: .accepted,
            isCompleted: false
        ),
        ItemClaim(
            id: "claim-3",
            tripId: "test-partial-1",
            itemId: "item-partial-1",
            claimerUserId: "test-user-4",
            quantityClaimed: 8,
            claimedAt: Date().addingTimeInterval(-1800), // 30 min ago
            status: .pending,
            isCompleted: false
        )
    ]
    // Claimed: 15 + 10 + 8 = 33 out of 40 (7 remaining)

    // MARK: - Test Comments

    static let testComments = [
        ItemComment(
            id: "comment-1",
            tripId: "test-potluck-1",
            itemId: "item-potluck-1",
            userId: "test-user-2",
            text: "I can get these from Trader Joe's instead of Costco if that's easier",
            createdAt: Date().addingTimeInterval(-7200)
        ),
        ItemComment(
            id: "comment-2",
            tripId: "test-potluck-1",
            itemId: "item-potluck-1",
            userId: "test-user-3",
            text: "Prefer grape and cherry flavors over orange!",
            createdAt: Date().addingTimeInterval(-3600)
        ),
        ItemComment(
            id: "comment-3",
            tripId: "test-potluck-1",
            itemId: "item-potluck-1",
            userId: "test-user-1",
            text: "Running a bit late, can someone else grab these if I'm not there by 2pm?",
            createdAt: Date().addingTimeInterval(-900)
        ),
        ItemComment(
            id: "comment-4",
            tripId: "test-potluck-1",
            itemId: "item-potluck-2",
            userId: "test-user-4",
            text: "Should we get veggie patties too for vegetarians?",
            createdAt: Date().addingTimeInterval(-5400)
        )
    ]

    // MARK: - Edge Case Test Trips

    // Trip with fully claimed item
    static let fullyClaimedTestTrip = Trip(
        id: "test-full-1",
        groupId: "test-group-6",
        shopperId: "test-user-1",
        tripType: .potluckMeal,
        store: .other,
        scheduledDate: Date().addingTimeInterval(86400),
        items: [
            TripItem(
                id: "item-full-1",
                name: "Birthday Cake (1 needed)",
                quantityAvailable: 1,
                estimatedPrice: 45.00,
                category: .desserts,
                notes: "Already claimed - test fully claimed state"
            )
        ],
        status: .planned,
        participants: ["test-user-2"]
    )

    static let fullyClaimedTestClaim = ItemClaim(
        id: "claim-full-1",
        tripId: "test-full-1",
        itemId: "item-full-1",
        claimerUserId: "test-user-2",
        quantityClaimed: 1,
        claimedAt: Date().addingTimeInterval(-3600),
        status: .accepted,
        isCompleted: false
    )

    // Trip with all items completed
    static let allCompletedTestTrip = Trip(
        id: "test-completed-1",
        groupId: "test-group-7",
        shopperId: "test-user-1",
        tripType: .eventPlanning,
        store: .other,
        scheduledDate: Date().addingTimeInterval(86400),
        items: [
            TripItem(
                id: "item-comp-1",
                name: "Balloons",
                quantityAvailable: 20,
                estimatedPrice: 0.30,
                category: .decorations,
                isCompleted: true
            ),
            TripItem(
                id: "item-comp-2",
                name: "Cake",
                quantityAvailable: 1,
                estimatedPrice: 45.00,
                category: .desserts,
                isCompleted: true
            )
        ],
        status: .planned,
        participants: ["test-user-2", "test-user-3"]
    )

    static let allCompletedTestClaims = [
        ItemClaim(
            id: "claim-comp-1",
            tripId: "test-completed-1",
            itemId: "item-comp-1",
            claimerUserId: "test-user-2",
            quantityClaimed: 20,
            status: .accepted,
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-1800)
        ),
        ItemClaim(
            id: "claim-comp-2",
            tripId: "test-completed-1",
            itemId: "item-comp-2",
            claimerUserId: "test-user-3",
            quantityClaimed: 1,
            status: .accepted,
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-900)
        )
    ]

    // MARK: - All Test Trips Array

    static let allTestTrips = [
        testBulkShoppingTrip,
        testEventPlanningTrip,
        testPotluckTrip,
        testGroupTrip,
        partialClaimingTestTrip,
        fullyClaimedTestTrip,
        allCompletedTestTrip
    ]
}

// MARK: - Test Users

struct TestUser {
    let id: String
    let name: String
    let email: String

    static let user1 = TestUser(id: "test-user-1", name: "Alice Johnson", email: "alice@test.com")
    static let user2 = TestUser(id: "test-user-2", name: "Bob Smith", email: "bob@test.com")
    static let user3 = TestUser(id: "test-user-3", name: "Carol Davis", email: "carol@test.com")
    static let user4 = TestUser(id: "test-user-4", name: "Dave Wilson", email: "dave@test.com")
    static let user5 = TestUser(id: "test-user-5", name: "Emma Brown", email: "emma@test.com")

    static let allTestUsers = [user1, user2, user3, user4, user5]
}

// MARK: - Test Groups

extension Group {
    static let testGroups = [
        Group(
            id: "test-group-1",
            name: "Family Bulk Buyers",
            description: "Weekly bulk shopping group",
            members: ["test-user-1", "test-user-2", "test-user-3"],
            icon: "👨‍👩‍👧‍👦",
            adminId: "test-user-1"
        ),
        Group(
            id: "test-group-2",
            name: "Party Planning Squad",
            description: "Event coordination group",
            members: ["test-user-1", "test-user-2", "test-user-3", "test-user-4"],
            icon: "🎉",
            adminId: "test-user-2"
        ),
        Group(
            id: "test-group-3",
            name: "Neighborhood Potlucks",
            description: "Monthly potluck dinners",
            members: ["test-user-1", "test-user-2", "test-user-3", "test-user-4", "test-user-5"],
            icon: "🏘️",
            adminId: "test-user-3"
        ),
        Group(
            id: "test-group-4",
            name: "Outdoor Adventures",
            description: "Camping and hiking trips",
            members: ["test-user-1", "test-user-2", "test-user-3", "test-user-4", "test-user-5"],
            icon: "⛰️",
            adminId: "test-user-4"
        )
    ]
}

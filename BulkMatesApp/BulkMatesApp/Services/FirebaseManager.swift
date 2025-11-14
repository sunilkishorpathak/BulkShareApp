//
//  FirebaseManager.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import UIKit

// MARK: - Custom Auth UI Delegate for reCAPTCHA
class PhoneAuthUIDelegate: NSObject, AuthUIDelegate {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {

        // Get the top-most view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            topController.present(viewControllerToPresent, animated: flag, completion: completion)
            completion?()
        }
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            topController.dismiss(animated: flag, completion: completion)
            completion?()
        }
    }
}

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    init() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Listen for authentication state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.loadCurrentUser(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(
        email: String,
        password: String,
        fullName: String,
        paypalId: String,
        address: Address? = nil,
        countryCode: String? = nil,
        phoneNumber: String? = nil
    ) async -> Result<Void, Error> {
        isLoading = true

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            try await result.user.sendEmailVerification()

            let newUser = User(
                id: result.user.uid,
                name: fullName,
                email: email,
                paypalId: paypalId,
                isEmailVerified: false,
                address: address,
                countryCode: countryCode,
                phoneNumber: phoneNumber
            )

            try await saveUser(newUser)
            
            // Send welcome email
            Task {
                let _ = await EmailService.shared.sendWelcomeEmail(to: email, userName: fullName)
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return .success(())
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return .failure(error)
        }
    }
    
    func signIn(email: String, password: String) async -> Result<Void, Error> {
        isLoading = true
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await result.user.reload()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return .success(())
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return .failure(error)
        }
    }
    
    func sendPasswordReset(email: String) async -> Result<Void, Error> {
        print("📧 Attempting to send password reset email to: \(email)")

        do {
            // Send password reset email via Firebase
            try await auth.sendPasswordReset(withEmail: email)
            print("✅ Password reset email sent successfully to: \(email)")
            print("📬 Check your spam folder if you don't see it in inbox")
            return .success(())
        } catch let error as NSError {
            print("❌ Failed to send password reset email")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error description: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func signOut() -> Result<Void, Error> {
        do {
            try auth.signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func deleteAccount() async -> Result<Void, Error> {
        guard let firebaseUser = auth.currentUser else {
            return .failure(AuthError.noCurrentUser)
        }
        
        isLoading = true
        
        do {
            // Use Firebase Auth user ID if currentUser isn't loaded yet
            let userIdToDelete = currentUser?.id ?? firebaseUser.uid
            
            // Delete user data from Firestore
            try await deleteUserData(userId: userIdToDelete)
            
            // Delete Firebase Auth account
            try await firebaseUser.delete()
            
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
            }
            
            return .success(())
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return .failure(error)
        }
    }
    
    private func deleteUserData(userId: String) async throws {
        let batch = firestore.batch()
        
        // Delete user document
        let userRef = firestore.collection("users").document(userId)
        batch.deleteDocument(userRef)
        
        // Find and delete user's groups where they are admin
        let adminGroupsSnapshot = try await firestore.collection("groups")
            .whereField("adminId", isEqualTo: userId)
            .getDocuments()
        
        for document in adminGroupsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Remove user from groups where they are members
        let memberGroupsSnapshot = try await firestore.collection("groups")
            .whereField("members", arrayContains: userId)
            .getDocuments()
        
        for document in memberGroupsSnapshot.documents {
            let groupRef = document.reference
            var members = document.data()["members"] as? [String] ?? []
            members.removeAll { $0 == userId }
            batch.updateData(["members": members], forDocument: groupRef)
        }
        
        // Find and delete user's trips where they are shopper
        let shopperTripsSnapshot = try await firestore.collection("trips")
            .whereField("shopperId", isEqualTo: userId)
            .getDocuments()
        
        for document in shopperTripsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Remove user from trips where they are participants
        let participantTripsSnapshot = try await firestore.collection("trips")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        
        for document in participantTripsSnapshot.documents {
            let tripRef = document.reference
            var participants = document.data()["participants"] as? [String] ?? []
            participants.removeAll { $0 == userId }
            batch.updateData(["participants": participants], forDocument: tripRef)
        }
        
        // Commit the batch
        try await batch.commit()
    }
    
    // MARK: - User Management
    
    private func loadCurrentUser(uid: String) {
        Task {
            do {
                let user = try await getUser(uid: uid)
                DispatchQueue.main.async {
                    self.currentUser = user
                    print("✅ User loaded successfully: \(user.email)")
                }
            } catch {
                print("❌ Error loading current user: \(error)")
                // If Firestore user doesn't exist, create a basic user from Firebase Auth
                if let authUser = auth.currentUser {
                    let basicUser = User(
                        id: authUser.uid,
                        name: authUser.displayName ?? "User",
                        email: authUser.email ?? "",
                        paypalId: "",
                        isEmailVerified: authUser.isEmailVerified
                    )
                    DispatchQueue.main.async {
                        self.currentUser = basicUser
                    }
                }
            }
        }
    }
    
    func saveUser(_ user: User) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "paypalId": user.paypalId,
            "createdAt": user.createdAt,
            "isEmailVerified": user.isEmailVerified
        ]
        
        try await firestore.collection("users").document(user.id).setData(userData)
    }
    
    func getUser(uid: String) async throws -> User {
        let document = try await firestore.collection("users").document(uid).getDocument()
        
        guard let data = document.data() else {
            throw FirestoreError.documentNotFound
        }
        
        return User(
            id: data["id"] as? String ?? uid,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            paypalId: data["paypalId"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            isEmailVerified: data["isEmailVerified"] as? Bool ?? false
        )
    }
    
    // MARK: - Group Management
    
    func createGroup(_ group: Group) async throws -> String {
        var groupData: [String: Any] = [
            "id": group.id,
            "name": group.name,
            "description": group.description,
            "members": group.members,
            "invitedEmails": group.invitedEmails,
            "icon": group.icon,
            "createdAt": group.createdAt,
            "adminId": group.adminId,
            "isActive": group.isActive,
            "inviteCode": group.inviteCode
        ]

        if let iconUrl = group.iconUrl {
            groupData["iconUrl"] = iconUrl
        }

        let docRef = try await firestore.collection("groups").addDocument(data: groupData)
        return docRef.documentID
    }
    
    func getAllGroups() async throws -> [Group] {
        let snapshot = try await firestore.collection("groups")
            .getDocuments()
        
        let groups = snapshot.documents.compactMap { doc -> Group? in
            let data = doc.data()
            let group = Group(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                members: data["members"] as? [String] ?? [],
                invitedEmails: data["invitedEmails"] as? [String] ?? [],
                icon: data["icon"] as? String ?? "👥",
                iconUrl: data["iconUrl"] as? String,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                adminId: data["adminId"] as? String ?? "",
                isActive: data["isActive"] as? Bool ?? true,
                inviteCode: data["inviteCode"] as? String
            )
            
            // Filter active groups client-side
            return group.isActive ? group : nil
        }
        
        // Sort by creation date client-side
        return groups.sorted { $0.createdAt > $1.createdAt }
    }
    
    func updateGroup(_ group: Group) async throws {
        var groupData: [String: Any] = [
            "name": group.name,
            "description": group.description,
            "members": group.members,
            "invitedEmails": group.invitedEmails,
            "icon": group.icon,
            "adminId": group.adminId,
            "isActive": group.isActive,
            "inviteCode": group.inviteCode
        ]

        if let iconUrl = group.iconUrl {
            groupData["iconUrl"] = iconUrl
        }

        try await firestore.collection("groups").document(group.id).updateData(groupData)
    }
    
    func getUserGroups() async throws -> [Group] {
        guard let currentUser = currentUser else { return [] }
        
        let snapshot = try await firestore.collection("groups")
            .whereField("members", arrayContains: currentUser.id)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return Group(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                description: data["description"] as? String ?? "",
                members: data["members"] as? [String] ?? [],
                invitedEmails: data["invitedEmails"] as? [String] ?? [],
                icon: data["icon"] as? String ?? "👥",
                iconUrl: data["iconUrl"] as? String,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                adminId: data["adminId"] as? String ?? "",
                isActive: data["isActive"] as? Bool ?? true,
                inviteCode: data["inviteCode"] as? String
            )
        }
    }

    // MARK: - Invite Code Functions

    func findGroupByInviteCode(_ inviteCode: String) async throws -> Group {
        #if DEBUG
        print("🔍 Finding group with invite code: \(inviteCode)")
        #endif

        let snapshot = try await firestore.collection("groups")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            #if DEBUG
            print("❌ No group found with invite code: \(inviteCode)")
            #endif
            throw NSError(domain: "BulkMates", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
        }

        let data = document.data()

        #if DEBUG
        print("✅ Found group document ID: \(document.documentID)")
        print("   Group name: \(data["name"] as? String ?? "Unknown")")
        print("   Members: \(data["members"] as? [String] ?? [])")
        #endif

        // CRITICAL FIX: Always use document.documentID (actual Firestore document ID)
        // NOT data["id"] which may be different from the document ID
        return Group(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            description: data["description"] as? String ?? "",
            members: data["members"] as? [String] ?? [],
            invitedEmails: data["invitedEmails"] as? [String] ?? [],
            icon: data["icon"] as? String ?? "👥",
            iconUrl: data["iconUrl"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            adminId: data["adminId"] as? String ?? "",
            isActive: data["isActive"] as? Bool ?? true,
            inviteCode: data["inviteCode"] as? String
        )
    }

    func joinGroupWithInviteCode(groupId: String, userId: String) async throws {
        #if DEBUG
        print("👥 Joining group...")
        print("   Group ID: \(groupId)")
        print("   User ID: \(userId)")
        #endif

        let groupRef = firestore.collection("groups").document(groupId)

        // First, verify the document exists
        let document = try await groupRef.getDocument()
        guard document.exists else {
            #if DEBUG
            print("❌ Group document does not exist with ID: \(groupId)")
            #endif
            throw NSError(
                domain: "BulkMates",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Group not found. The group may have been deleted."]
            )
        }

        #if DEBUG
        print("✅ Group document exists, adding member...")
        #endif

        // Add user to members array
        try await groupRef.updateData([
            "members": FieldValue.arrayUnion([userId])
        ])

        #if DEBUG
        print("✅ Successfully added user to group!")
        #endif
    }

    func leaveGroup(groupId: String, userId: String) async throws {
        let groupRef = firestore.collection("groups").document(groupId)

        // Remove user from members array
        try await groupRef.updateData([
            "members": FieldValue.arrayRemove([userId])
        ])

    }

    func deleteGroup(groupId: String) async throws {
        // Step 1: Delete all trips associated with this group
        let tripsSnapshot = try await firestore.collection("trips")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments()

        // Delete all trips in batch
        let batch = firestore.batch()
        for document in tripsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        try await batch.commit()

        // Step 2: Delete the group document
        try await firestore.collection("groups").document(groupId).delete()

    }

    // MARK: - Trip Management

    
    func createTrip(_ trip: Trip) async throws -> String {
        let tripData: [String: Any] = [
            "id": trip.id,
            "name": trip.name,
            "groupId": trip.groupId,
            "shopperId": trip.shopperId,
            "tripType": trip.tripType.rawValue,
            "store": trip.store.rawValue,
            "scheduledDate": trip.scheduledDate,
            "items": trip.items.map { item in
                var itemData: [String: Any] = [
                    "id": item.id,
                    "name": item.name,
                    "quantityAvailable": item.quantityAvailable,
                    "estimatedPrice": item.estimatedPrice,
                    "category": item.category.rawValue,
                    "notes": item.notes ?? ""
                ]
                // Add imageURL if present
                if let imageURL = item.imageURL {
                    itemData["imageURL"] = imageURL
                }
                return itemData
            },
            "status": trip.status.rawValue,
            "createdAt": trip.createdAt,
            "participants": trip.participants,
            "notes": trip.notes ?? "",
            "creatorId": trip.creatorId,
            "adminIds": trip.adminIds,
            "viewerIds": trip.viewerIds
        ]
        
        let docRef = try await firestore.collection("trips").addDocument(data: tripData)
        
        // Send notifications to group members
        let group = try await getGroup(groupId: trip.groupId)
        try await NotificationManager.shared.createTripNotification(
            tripId: docRef.documentID,
            trip: trip,
            creatorUserId: trip.shopperId,
            creatorName: currentUser?.name ?? "Someone",
            groupMembers: group.members
        )
        
        return docRef.documentID
    }
    
    func getTrip(tripId: String) async throws -> Trip {
        let document = try await firestore.collection("trips").document(tripId).getDocument()

        guard let data = document.data() else {
            throw FirestoreError.documentNotFound
        }

        let items = (data["items"] as? [[String: Any]] ?? []).compactMap { itemData in
            TripItem(
                id: itemData["id"] as? String ?? UUID().uuidString,
                name: itemData["name"] as? String ?? "",
                quantityAvailable: itemData["quantityAvailable"] as? Int ?? 1,
                estimatedPrice: itemData["estimatedPrice"] as? Double ?? 0.0,
                category: ItemCategory(rawValue: itemData["category"] as? String ?? "grocery") ?? .grocery,
                notes: itemData["notes"] as? String,
                imageURL: itemData["imageURL"] as? String
            )
        }

        // Parse tripType with backward compatibility
        let tripTypeRawValue = data["tripType"] as? String ?? "shopping"
        let tripType = TripType(rawValue: tripTypeRawValue) ?? .shopping

        return Trip(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            groupId: data["groupId"] as? String ?? "",
            shopperId: data["shopperId"] as? String ?? "",
            tripType: tripType,
            store: Store(rawValue: data["store"] as? String ?? "costco") ?? .costco,
            scheduledDate: (data["scheduledDate"] as? Timestamp)?.dateValue() ?? Date(),
            items: items,
            status: TripStatus(rawValue: data["status"] as? String ?? "planned") ?? .planned,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            participants: data["participants"] as? [String] ?? [],
            notes: data["notes"] as? String,
            activityCount: data["activityCount"] as? Int ?? 0,
            lastActivityTimestamp: (data["lastActivityTimestamp"] as? Timestamp)?.dateValue(),
            creatorId: data["creatorId"] as? String ?? "",
            adminIds: data["adminIds"] as? [String] ?? [],
            viewerIds: data["viewerIds"] as? [String] ?? []
        )
    }
    
    func updateTrip(_ trip: Trip) async throws {
        let tripData: [String: Any] = [
            "name": trip.name,
            "tripType": trip.tripType.rawValue,
            "store": trip.store.rawValue,
            "scheduledDate": trip.scheduledDate,
            "status": trip.status.rawValue,
            "notes": trip.notes ?? "",
            "adminIds": trip.adminIds,
            "viewerIds": trip.viewerIds,
            "items": trip.items.map { item in
                [
                    "id": item.id,
                    "name": item.name,
                    "quantityAvailable": item.quantityAvailable,
                    "estimatedPrice": item.estimatedPrice,
                    "category": item.category.rawValue,
                    "notes": item.notes ?? "",
                    "imageURL": item.imageURL ?? ""
                ]
            }
        ]

        try await firestore.collection("trips").document(trip.id).updateData(tripData)
    }

    func getGroup(groupId: String) async throws -> Group {
        let document = try await firestore.collection("groups").document(groupId).getDocument()
        
        guard let data = document.data() else {
            throw FirestoreError.documentNotFound
        }
        
        return Group(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            description: data["description"] as? String ?? "",
            members: data["members"] as? [String] ?? [],
            invitedEmails: data["invitedEmails"] as? [String] ?? [],
            icon: data["icon"] as? String ?? "👥",
            iconUrl: data["iconUrl"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            adminId: data["adminId"] as? String ?? "",
            isActive: data["isActive"] as? Bool ?? true
        )
    }
    
    func getUserTrips() async throws -> [Trip] {
        guard let currentUser = currentUser else { return [] }
        
        // Get all trips and filter client-side to avoid complex indexing
        let snapshot = try await firestore.collection("trips")
            .getDocuments()
        
        let allTrips = snapshot.documents.compactMap { document -> Trip? in
            guard let trip = parseTrip(from: document) else { return nil }
            
            // Include trips where user is shopper or participant
            if trip.shopperId == currentUser.id || trip.participants.contains(currentUser.id) {
                return trip
            }
            
            return nil
        }
        
        return allTrips.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    private func parseTrip(from document: QueryDocumentSnapshot) -> Trip? {
        let data = document.data()

        let items = (data["items"] as? [[String: Any]] ?? []).compactMap { itemData in
            TripItem(
                id: itemData["id"] as? String ?? UUID().uuidString,
                name: itemData["name"] as? String ?? "",
                quantityAvailable: itemData["quantityAvailable"] as? Int ?? 1,
                estimatedPrice: itemData["estimatedPrice"] as? Double ?? 0.0,
                category: ItemCategory(rawValue: itemData["category"] as? String ?? "grocery") ?? .grocery,
                notes: itemData["notes"] as? String,
                imageURL: itemData["imageURL"] as? String
            )
        }

        // Parse tripType with backward compatibility
        let tripTypeRawValue = data["tripType"] as? String ?? "shopping"
        let tripType = TripType(rawValue: tripTypeRawValue) ?? .shopping

        return Trip(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            groupId: data["groupId"] as? String ?? "",
            shopperId: data["shopperId"] as? String ?? "",
            tripType: tripType,
            store: Store(rawValue: data["store"] as? String ?? "costco") ?? .costco,
            scheduledDate: (data["scheduledDate"] as? Timestamp)?.dateValue() ?? Date(),
            items: items,
            status: TripStatus(rawValue: data["status"] as? String ?? "planned") ?? .planned,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            participants: data["participants"] as? [String] ?? [],
            notes: data["notes"] as? String,
            activityCount: data["activityCount"] as? Int ?? 0,
            lastActivityTimestamp: (data["lastActivityTimestamp"] as? Timestamp)?.dateValue(),
            creatorId: data["creatorId"] as? String ?? "",
            adminIds: data["adminIds"] as? [String] ?? [],
            viewerIds: data["viewerIds"] as? [String] ?? []
        )
    }
    
    func getGroupTrips(groupId: String) async throws -> [Trip] {
        let snapshot = try await firestore.collection("trips")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments()
        
        let trips = snapshot.documents.compactMap { parseTrip(from: $0) }
        // Sort in-memory by scheduledDate
        return trips.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    // MARK: - Claims Management
    
    func createClaims(_ claims: [ItemClaim]) async throws {
        let batch = firestore.batch()
        
        for claim in claims {
            let claimData: [String: Any] = [
                "id": claim.id,
                "tripId": claim.tripId,
                "itemId": claim.itemId,
                "claimerUserId": claim.claimerUserId,
                "quantityClaimed": claim.quantityClaimed,
                "claimedAt": claim.claimedAt,
                "status": claim.status.rawValue
            ]
            
            let docRef = firestore.collection("claims").document(claim.id)
            batch.setData(claimData, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    func getTripClaims(tripId: String) async throws -> [ItemClaim] {
        let snapshot = try await firestore.collection("claims")
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return ItemClaim(
                id: data["id"] as? String ?? document.documentID,
                tripId: data["tripId"] as? String ?? "",
                itemId: data["itemId"] as? String ?? "",
                claimerUserId: data["claimerUserId"] as? String ?? "",
                quantityClaimed: data["quantityClaimed"] as? Int ?? 0,
                claimedAt: (data["claimedAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: ClaimStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending
            )
        }
    }
    
    func getUserClaims(userId: String) async throws -> [ItemClaim] {
        let snapshot = try await firestore.collection("claims")
            .whereField("claimerUserId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return ItemClaim(
                id: data["id"] as? String ?? document.documentID,
                tripId: data["tripId"] as? String ?? "",
                itemId: data["itemId"] as? String ?? "",
                claimerUserId: data["claimerUserId"] as? String ?? "",
                quantityClaimed: data["quantityClaimed"] as? Int ?? 0,
                claimedAt: (data["claimedAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: ClaimStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending
            )
        }
    }
    
    func updateClaimStatus(claimId: String, status: ClaimStatus) async throws {
        try await firestore.collection("claims").document(claimId)
            .updateData(["status": status.rawValue])
    }
    
    // MARK: - Item Request Management
    
    func createItemRequest(_ request: ItemRequest) async throws {
        let requestData: [String: Any] = [
            "id": request.id,
            "tripId": request.tripId,
            "requesterUserId": request.requesterUserId,
            "itemName": request.itemName,
            "quantityRequested": request.quantityRequested,
            "category": request.category.rawValue,
            "notes": request.notes as Any,
            "requestedAt": Timestamp(date: request.requestedAt),
            "status": request.status.rawValue
        ]
        
        try await firestore.collection("itemRequests")
            .document(request.id)
            .setData(requestData)
    }
    
    func getTripItemRequests(tripId: String) async throws -> [ItemRequest] {
        let snapshot = try await firestore.collection("itemRequests")
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let category = ItemCategory(rawValue: data["category"] as? String ?? "") else {
                return nil
            }
            
            return ItemRequest(
                id: data["id"] as? String ?? document.documentID,
                tripId: data["tripId"] as? String ?? "",
                requesterUserId: data["requesterUserId"] as? String ?? "",
                itemName: data["itemName"] as? String ?? "",
                quantityRequested: data["quantityRequested"] as? Int ?? 0,
                category: category,
                notes: data["notes"] as? String,
                requestedAt: (data["requestedAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: ItemRequestStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending
            )
        }
    }
    
    func updateItemRequestStatus(requestId: String, status: ItemRequestStatus) async throws {
        try await firestore.collection("itemRequests").document(requestId)
            .updateData(["status": status.rawValue])
    }
    
    func approveItemRequestAndAddToTrip(requestId: String, tripId: String) async throws {
        // First get the request details
        let requestDoc = try await firestore.collection("itemRequests").document(requestId).getDocument()
        guard let requestData = requestDoc.data(),
              let itemName = requestData["itemName"] as? String,
              let quantityRequested = requestData["quantityRequested"] as? Int,
              let categoryRaw = requestData["category"] as? String,
              let category = ItemCategory(rawValue: categoryRaw) else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request data"])
        }
        
        // Create new trip item
        let newTripItem = TripItem(
            name: itemName,
            quantityAvailable: quantityRequested,
            estimatedPrice: 0.0,
            category: category,
            notes: requestData["notes"] as? String
        )
        
        // Update trip with new item and request status in a batch
        let batch = firestore.batch()
        
        // Update request status
        let requestRef = firestore.collection("itemRequests").document(requestId)
        batch.updateData(["status": ItemRequestStatus.approved.rawValue], forDocument: requestRef)
        
        // Add item to trip
        let tripRef = firestore.collection("trips").document(tripId)
        batch.updateData([
            "items": FieldValue.arrayUnion([[
                "id": newTripItem.id,
                "name": newTripItem.name,
                "quantityAvailable": newTripItem.quantityAvailable,
                "estimatedPrice": newTripItem.estimatedPrice,
                "category": newTripItem.category.rawValue,
                "notes": newTripItem.notes as Any
            ]])
        ], forDocument: tripRef)
        
        try await batch.commit()
    }
    
    // MARK: - Transaction Management
    
    func createTransaction(_ transaction: Transaction) async throws {
        let transactionData: [String: Any] = [
            "id": transaction.id,
            "tripId": transaction.tripId,
            "fromUserId": transaction.fromUserId,
            "toUserId": transaction.toUserId,
            "itemPoints": transaction.itemPoints,
            "itemClaimIds": transaction.itemClaimIds,
            "createdAt": transaction.createdAt,
            "status": transaction.status.rawValue,
            "notes": transaction.notes ?? ""
        ]
        
        try await firestore.collection("transactions").document(transaction.id).setData(transactionData)
    }
    
    func getTripTransactions(tripId: String) async throws -> [Transaction] {
        let snapshot = try await firestore.collection("transactions")
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return Transaction(
                id: data["id"] as? String ?? document.documentID,
                tripId: data["tripId"] as? String ?? "",
                fromUserId: data["fromUserId"] as? String ?? "",
                toUserId: data["toUserId"] as? String ?? "",
                itemPoints: data["itemPoints"] as? Int ?? data["amount"] as? Int ?? 0,
                itemClaimIds: data["itemClaimIds"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TransactionStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                settledAt: (data["settledAt"] as? Timestamp)?.dateValue() ?? (data["paidAt"] as? Timestamp)?.dateValue(),
                notes: data["notes"] as? String
            )
        }
    }
    
    func getUserTransactions(userId: String) async throws -> [Transaction] {
        // Get transactions where user is either sender or receiver
        let sentSnapshot = try await firestore.collection("transactions")
            .whereField("fromUserId", isEqualTo: userId)
            .getDocuments()
        
        let receivedSnapshot = try await firestore.collection("transactions")
            .whereField("toUserId", isEqualTo: userId)
            .getDocuments()
        
        var transactions: [Transaction] = []
        
        // Parse sent transactions
        for document in sentSnapshot.documents {
            let data = document.data()
            let transaction = Transaction(
                id: data["id"] as? String ?? document.documentID,
                tripId: data["tripId"] as? String ?? "",
                fromUserId: data["fromUserId"] as? String ?? "",
                toUserId: data["toUserId"] as? String ?? "",
                itemPoints: data["itemPoints"] as? Int ?? data["amount"] as? Int ?? 0,
                itemClaimIds: data["itemClaimIds"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TransactionStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                settledAt: (data["settledAt"] as? Timestamp)?.dateValue() ?? (data["paidAt"] as? Timestamp)?.dateValue(),
                notes: data["notes"] as? String
            )
            transactions.append(transaction)
        }
        
        // Parse received transactions
        for document in receivedSnapshot.documents {
            let data = document.data()
            let transaction = Transaction(
                id: data["id"] as? String ?? document.documentID,
                tripId: data["tripId"] as? String ?? "",
                fromUserId: data["fromUserId"] as? String ?? "",
                toUserId: data["toUserId"] as? String ?? "",
                itemPoints: data["itemPoints"] as? Int ?? data["amount"] as? Int ?? 0,
                itemClaimIds: data["itemClaimIds"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TransactionStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                settledAt: (data["settledAt"] as? Timestamp)?.dateValue() ?? (data["paidAt"] as? Timestamp)?.dateValue(),
                notes: data["notes"] as? String
            )
            transactions.append(transaction)
        }
        
        // Remove duplicates and sort by date
        let uniqueTransactions = Array(Set(transactions.map { $0.id })).compactMap { id in
            transactions.first { $0.id == id }
        }
        
        return uniqueTransactions.sorted { $0.createdAt > $1.createdAt }
    }
    
    func markTransactionAsSettled(_ transactionId: String) async throws {
        try await firestore.collection("transactions").document(transactionId).updateData([
            "status": TransactionStatus.settled.rawValue,
            "settledAt": Date()
        ])
    }
    
    func getUserBalance(userId: String) async throws -> UserBalance {
        let transactions = try await getUserTransactions(userId: userId)
        
        var totalItemsOwed: Int = 0
        var totalItemsOwedTo: Int = 0
        
        for transaction in transactions where transaction.status == .pending {
            if transaction.fromUserId == userId {
                totalItemsOwed += transaction.itemPoints
            } else if transaction.toUserId == userId {
                totalItemsOwedTo += transaction.itemPoints
            }
        }
        
        return UserBalance(
            id: UUID().uuidString,
            userId: userId,
            totalItemsOwed: totalItemsOwed,
            totalItemsOwedTo: totalItemsOwedTo,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Item Delivery Methods
    
    func createDeliveryRecords(for claims: [ItemClaim], delivererUserId: String) async throws {
        let batch = firestore.batch()
        
        for claim in claims where claim.status == .accepted {
            let delivery = ItemDelivery.createFromClaim(claim, delivererUserId: delivererUserId)
            let deliveryRef = firestore.collection("deliveries").document(delivery.id)
            
            do {
                let deliveryData = try Firestore.Encoder().encode(delivery)
                batch.setData(deliveryData, forDocument: deliveryRef)
            } catch {
                throw error
            }
        }
        
        try await batch.commit()
    }
    
    func getTripDeliveries(tripId: String) async throws -> [ItemDelivery] {
        let snapshot = try await firestore.collection("deliveries")
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments()
        
        var deliveries: [ItemDelivery] = []
        
        for document in snapshot.documents {
            do {
                let delivery = try document.data(as: ItemDelivery.self)
                deliveries.append(delivery)
            } catch {
                print("Error decoding delivery: \(error)")
            }
        }
        
        return deliveries.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getUserDeliveries(userId: String) async throws -> [ItemDelivery] {
        let snapshot = try await firestore.collection("deliveries")
            .whereField("receiverUserId", isEqualTo: userId)
            .getDocuments()
        
        var deliveries: [ItemDelivery] = []
        
        for document in snapshot.documents {
            do {
                let delivery = try document.data(as: ItemDelivery.self)
                deliveries.append(delivery)
            } catch {
                print("Error decoding delivery: \(error)")
            }
        }
        
        return deliveries.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getDeliveriesToMake(delivererUserId: String) async throws -> [ItemDelivery] {
        let snapshot = try await firestore.collection("deliveries")
            .whereField("delivererUserId", isEqualTo: delivererUserId)
            .whereField("isDelivered", isEqualTo: false)
            .getDocuments()
        
        var deliveries: [ItemDelivery] = []
        
        for document in snapshot.documents {
            do {
                let delivery = try document.data(as: ItemDelivery.self)
                deliveries.append(delivery)
            } catch {
                print("Error decoding delivery: \(error)")
            }
        }
        
        return deliveries.sorted { $0.createdAt > $1.createdAt }
    }
    
    func markItemAsDelivered(deliveryId: String, deliveredAt: Date, confirmationNote: String?) async throws {
        var updateData: [String: Any] = [
            "isDelivered": true,
            "deliveredAt": deliveredAt
        ]
        
        if let note = confirmationNote {
            updateData["confirmationNote"] = note
        }
        
        try await firestore.collection("deliveries").document(deliveryId).updateData(updateData)
    }
    
    func markItemAsNotDelivered(deliveryId: String) async throws {
        try await firestore.collection("deliveries").document(deliveryId).updateData([
            "isDelivered": false,
            "deliveredAt": FieldValue.delete(),
            "confirmationNote": FieldValue.delete()
        ])
    }
    
    func createDeliveryRecord(_ delivery: ItemDelivery) async throws {
        do {
            let deliveryData = try Firestore.Encoder().encode(delivery)
            try await firestore.collection("deliveries").document(delivery.id).setData(deliveryData)
        } catch {
            throw error
        }
    }
    
    func autoCreateDeliveryRecordsForCompletedTrip(tripId: String) async throws {
        // Get all accepted claims for this trip
        let claims = try await getTripClaims(tripId: tripId)
        let acceptedClaims = claims.filter { $0.status == .accepted }
        
        // Get the trip to find the shopper
        let trip = try await getTrip(tripId: tripId)
        
        // Create delivery records for all accepted claims
        try await createDeliveryRecords(for: acceptedClaims, delivererUserId: trip.shopperId)
    }
    
    func markTripAsCompleted(tripId: String) async throws {
        // Update trip status to completed
        try await firestore.collection("trips").document(tripId).updateData([
            "status": TripStatus.completed.rawValue
        ])
        
        // Automatically create delivery records for all accepted claims
        try await autoCreateDeliveryRecordsForCompletedTrip(tripId: tripId)
    }
    
    func updateTripStatus(tripId: String, status: TripStatus) async throws {
        try await firestore.collection("trips").document(tripId).updateData([
            "status": status.rawValue
        ])

        // If marking as completed, create delivery records
        if status == .completed {
            try await autoCreateDeliveryRecordsForCompletedTrip(tripId: tripId)
        }
    }

    func deleteTrip(tripId: String) async throws {
        // Delete trip document
        try await firestore.collection("trips").document(tripId).delete()
        print("✅ Successfully deleted plan \(tripId)")
    }

    // MARK: - Phone Verification Methods
    
    struct PhoneVerificationResult {
        let verificationID: String
        let attemptsRemaining: Int
        let resetTime: Int?
    }
    
    func sendPhoneVerification(phoneNumber: String) async throws -> PhoneVerificationResult {
        print("📞 Starting phone verification for: \(phoneNumber)")

        // Verify Firebase is configured
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase not configured!")
            throw PhoneVerificationError.sendFailed("Firebase not configured")
        }
        print("✅ Firebase app configured")

        // Verify Auth is available
        let auth = Auth.auth()
        print("✅ Auth instance: \(auth)")
        print("✅ Auth app: \(auth.app?.name ?? "nil")")

        // Default values (no rate limiting)
        let attemptsRemaining = 3
        let resetTime: Int? = nil

        // SKIP rate limiting for now - can be added later with Cloud Functions
        print("📝 Skipping rate limit check (Cloud Function not configured)")

        // Send SMS verification directly
        do {
            print("📤 Getting PhoneAuthProvider...")

            // Use explicit auth instance instead of singleton
            let provider = PhoneAuthProvider.provider(auth: auth)
            print("✅ Provider obtained: \(provider)")

            print("📤 Calling verifyPhoneNumber for: \(phoneNumber)")

            // Create custom UI delegate for reCAPTCHA verification
            let uiDelegate = PhoneAuthUIDelegate()
            print("✅ Created PhoneAuthUIDelegate for reCAPTCHA flow")

            let verificationID = try await provider.verifyPhoneNumber(
                phoneNumber,
                uiDelegate: uiDelegate
            )

            print("✅ Verification SMS sent successfully")
            print("🔑 Verification ID: \(verificationID)")

            return PhoneVerificationResult(
                verificationID: verificationID,
                attemptsRemaining: attemptsRemaining,
                resetTime: resetTime
            )
        } catch let error as NSError {
            print("❌ Failed to send verification SMS")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error description: \(error.localizedDescription)")
            print("❌ Error user info: \(error.userInfo)")

            throw PhoneVerificationError.sendFailed(error.localizedDescription)
        }
    }
    
    func verifyPhoneCode(
        verificationID: String, 
        verificationCode: String, 
        purpose: PhoneVerificationView.VerificationPurpose
    ) async throws {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        switch purpose {
        case .passwordReset:
            try await handlePasswordResetVerification(credential: credential)
        case .phoneLogin:
            try await handlePhoneLogin(credential: credential)
        case .changePhoneNumber:
            try await handlePhoneNumberChange(credential: credential)
        }
    }
    
    private func handlePasswordResetVerification(credential: PhoneAuthCredential) async throws {
        // For password reset, we don't actually sign in with the phone credential
        // We just verify the phone number belongs to the user
        
        // Try to sign in temporarily to verify the credential is valid
        let authResult = try await auth.signIn(with: credential)
        let phoneNumber = authResult.user.phoneNumber
        
        // Sign out the temporary session
        try auth.signOut()
        
        // Find user by phone number and send email reset
        guard let phoneNumber = phoneNumber else {
            throw PhoneVerificationError.verificationFailed
        }
        
        // Query users collection to find user with this phone number
        let usersQuery = firestore.collection("users")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .limit(to: 1)
        
        let snapshot = try await usersQuery.getDocuments()
        
        guard let document = snapshot.documents.first,
              let userData = try? document.data(as: User.self),
              !userData.email.isEmpty else {
            throw PhoneVerificationError.userNotFound
        }
        
        // Send password reset email
        try await auth.sendPasswordReset(withEmail: userData.email)
    }
    
    private func handlePhoneLogin(credential: PhoneAuthCredential) async throws {
        let authResult = try await auth.signIn(with: credential)
        let firebaseUser = authResult.user
        
        // Check if user exists in our database
        let userDoc = try await firestore.collection("users").document(firebaseUser.uid).getDocument()
        
        if !userDoc.exists {
            throw PhoneVerificationError.userNotFound
        }
        
        // Load user data
        try await loadCurrentUser(uid: firebaseUser.uid)
    }
    
    private func handlePhoneNumberChange(credential: PhoneAuthCredential) async throws {
        guard let firebaseUser = auth.currentUser else {
            throw AuthError.noCurrentUser
        }
        
        // Update phone number in Firebase Auth
        try await firebaseUser.updatePhoneNumber(credential)
        
        // Update phone number in Firestore - get from Firebase user after update
        if let phoneNumber = firebaseUser.phoneNumber {
            try await firestore.collection("users").document(firebaseUser.uid).updateData([
                "phoneNumber": phoneNumber
            ])
            
            // Reload current user to reflect changes
            try await loadCurrentUser(uid: firebaseUser.uid)
        }
    }
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case noCurrentUser
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found"
        }
    }
}

enum FirestoreError: LocalizedError {
    case documentNotFound
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Document not found"
        }
    }
}

enum PhoneVerificationError: LocalizedError {
    case rateLimitCheckFailed
    case rateLimitExceeded(message: String, resetTime: Int?)
    case sendFailed(String)
    case verificationFailed
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .rateLimitCheckFailed:
            return "Unable to check rate limits"
        case .rateLimitExceeded(let message, _):
            return message
        case .sendFailed(let message):
            return "Failed to send verification: \(message)"
        case .verificationFailed:
            return "Phone verification failed"
        case .userNotFound:
            return "No account found with this phone number"
        }
    }
}

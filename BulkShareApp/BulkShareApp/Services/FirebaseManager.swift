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
    
    func signUp(email: String, password: String, fullName: String, paypalId: String) async -> Result<Void, Error> {
        isLoading = true
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            try await result.user.sendEmailVerification()
            
            let newUser = User(
                id: result.user.uid,
                name: fullName,
                email: email,
                paypalId: paypalId,
                isEmailVerified: false
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
        do {
            try await auth.sendPasswordReset(withEmail: email)
            return .success(())
        } catch {
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
                        print("✅ Created basic user from Auth: \(basicUser.email)")
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
        let groupData: [String: Any] = [
            "id": group.id,
            "name": group.name,
            "description": group.description,
            "members": group.members,
            "invitedEmails": group.invitedEmails,
            "icon": group.icon,
            "createdAt": group.createdAt,
            "adminId": group.adminId,
            "isActive": group.isActive
        ]
        
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
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                adminId: data["adminId"] as? String ?? "",
                isActive: data["isActive"] as? Bool ?? true
            )
            
            // Filter active groups client-side
            return group.isActive ? group : nil
        }
        
        // Sort by creation date client-side
        return groups.sorted { $0.createdAt > $1.createdAt }
    }
    
    func updateGroup(_ group: Group) async throws {
        let groupData: [String: Any] = [
            "name": group.name,
            "description": group.description,
            "members": group.members,
            "invitedEmails": group.invitedEmails,
            "icon": group.icon,
            "adminId": group.adminId,
            "isActive": group.isActive
        ]
        
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
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                adminId: data["adminId"] as? String ?? "",
                isActive: data["isActive"] as? Bool ?? true
            )
        }
    }
    
    func createTrip(_ trip: Trip) async throws -> String {
        let tripData: [String: Any] = [
            "id": trip.id,
            "groupId": trip.groupId,
            "shopperId": trip.shopperId,
            "store": trip.store.rawValue,
            "scheduledDate": trip.scheduledDate,
            "items": trip.items.map { item in
                [
                    "id": item.id,
                    "name": item.name,
                    "quantityAvailable": item.quantityAvailable,
                    "estimatedPrice": item.estimatedPrice,
                    "category": item.category.rawValue,
                    "notes": item.notes ?? ""
                ]
            },
            "status": trip.status.rawValue,
            "createdAt": trip.createdAt,
            "participants": trip.participants,
            "notes": trip.notes ?? ""
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
                notes: itemData["notes"] as? String
            )
        }
        
        return Trip(
            id: document.documentID,
            groupId: data["groupId"] as? String ?? "",
            shopperId: data["shopperId"] as? String ?? "",
            store: Store(rawValue: data["store"] as? String ?? "costco") ?? .costco,
            scheduledDate: (data["scheduledDate"] as? Timestamp)?.dateValue() ?? Date(),
            items: items,
            status: TripStatus(rawValue: data["status"] as? String ?? "planned") ?? .planned,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            participants: data["participants"] as? [String] ?? [],
            notes: data["notes"] as? String
        )
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
                notes: itemData["notes"] as? String
            )
        }
        
        return Trip(
            id: document.documentID,
            groupId: data["groupId"] as? String ?? "",
            shopperId: data["shopperId"] as? String ?? "",
            store: Store(rawValue: data["store"] as? String ?? "costco") ?? .costco,
            scheduledDate: (data["scheduledDate"] as? Timestamp)?.dateValue() ?? Date(),
            items: items,
            status: TripStatus(rawValue: data["status"] as? String ?? "planned") ?? .planned,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            participants: data["participants"] as? [String] ?? [],
            notes: data["notes"] as? String
        )
    }
    
    func getGroupTrips(groupId: String) async throws -> [Trip] {
        let snapshot = try await firestore.collection("trips")
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "scheduledDate", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { parseTrip(from: $0) }
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
    
    // MARK: - Transaction Management
    
    func createTransaction(_ transaction: Transaction) async throws {
        let transactionData: [String: Any] = [
            "id": transaction.id,
            "tripId": transaction.tripId,
            "fromUserId": transaction.fromUserId,
            "toUserId": transaction.toUserId,
            "amount": transaction.amount,
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
                amount: data["amount"] as? Double ?? 0.0,
                itemClaimIds: data["itemClaimIds"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TransactionStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                paidAt: (data["paidAt"] as? Timestamp)?.dateValue(),
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
                amount: data["amount"] as? Double ?? 0.0,
                itemClaimIds: data["itemClaimIds"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TransactionStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                paidAt: (data["paidAt"] as? Timestamp)?.dateValue(),
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
                amount: data["amount"] as? Double ?? 0.0,
                itemClaimIds: data["itemClaimIds"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TransactionStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                paidAt: (data["paidAt"] as? Timestamp)?.dateValue(),
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
    
    func markTransactionAsPaid(_ transactionId: String) async throws {
        try await firestore.collection("transactions").document(transactionId).updateData([
            "status": TransactionStatus.paid.rawValue,
            "paidAt": Date()
        ])
    }
    
    func getUserBalance(userId: String) async throws -> UserBalance {
        let transactions = try await getUserTransactions(userId: userId)
        
        var totalOwed: Double = 0
        var totalOwedTo: Double = 0
        
        for transaction in transactions where transaction.status == .pending {
            if transaction.fromUserId == userId {
                totalOwed += transaction.amount
            } else if transaction.toUserId == userId {
                totalOwedTo += transaction.amount
            }
        }
        
        return UserBalance(
            id: UUID().uuidString,
            userId: userId,
            totalOwed: totalOwed,
            totalOwedTo: totalOwedTo,
            lastUpdated: Date()
        )
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

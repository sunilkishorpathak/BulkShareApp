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
            "icon": group.icon,
            "createdAt": group.createdAt,
            "adminId": group.adminId,
            "isActive": group.isActive
        ]
        
        let docRef = try await firestore.collection("groups").addDocument(data: groupData)
        return docRef.documentID
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
                icon: data["icon"] as? String ?? "👥",
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                adminId: data["adminId"] as? String ?? "",
                isActive: data["isActive"] as? Bool ?? true
            )
        }
    }
    
    func getGroupTrips(groupId: String) async throws -> [Trip] {
        let snapshot = try await firestore.collection("trips")
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "scheduledDate", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            
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
                id: doc.documentID,
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

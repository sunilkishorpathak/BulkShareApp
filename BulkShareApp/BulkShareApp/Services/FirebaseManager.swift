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
    
    // MARK: - User Management
    
    private func loadCurrentUser(uid: String) {
        Task {
            do {
                let user = try await getUser(uid: uid)
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            } catch {
                print("Error loading current user: \(error)")
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

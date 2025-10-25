//
//  UserProfileView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isDeleting = false
    @State private var showingEmailDebug = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingAcknowledgments = false
    
    // Computed properties for safe data access
    private var userEmail: String {
        return firebaseManager.currentUser?.email ?? 
               Auth.auth().currentUser?.email ?? 
               "No email available"
    }
    
    private var userEmailVerified: String {
        // Check both Firestore and Firebase Auth
        let firestoreVerified = firebaseManager.currentUser?.isEmailVerified ?? false
        let authVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        return (firestoreVerified || authVerified) ? "Yes" : "No"
    }
    
    private var userName: String {
        return firebaseManager.currentUser?.displayName ?? 
               Auth.auth().currentUser?.displayName ?? 
               "User"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                if isDeleting {
                    DeletingAccountView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            ProfileHeaderView(
                                userName: userName,
                                userEmail: userEmail
                            )
                            
                            // Account Settings Section
                            SettingsSection(title: "Account") {
                                ProfileSettingsRow(
                                    icon: "person.circle",
                                    title: "Email",
                                    value: userEmail,
                                    action: nil
                                )
                                
                                ProfileSettingsRow(
                                    icon: "checkmark.shield",
                                    title: "Email Verified",
                                    value: userEmailVerified,
                                    action: nil
                                )
                            }
                            
                            // Privacy & Data Section
                            SettingsSection(title: "Privacy & Data") {
                                ProfileSettingsRow(
                                    icon: "doc.text",
                                    title: "Privacy Policy",
                                    value: "",
                                    action: { showingPrivacyPolicy = true }
                                )
                                
                                ProfileSettingsRow(
                                    icon: "doc.plaintext",
                                    title: "Terms of Service",
                                    value: "",
                                    action: { showingTermsOfService = true }
                                )
                                
                                ProfileSettingsRow(
                                    icon: "hand.thumbsup",
                                    title: "Acknowledgments",
                                    value: "",
                                    action: { showingAcknowledgments = true }
                                )
                                
                                ProfileSettingsRow(
                                    icon: "envelope.badge",
                                    title: "Email Debug (Dev)",
                                    value: "",
                                    action: { showingEmailDebug = true }
                                )
                            }
                            
                            // Danger Zone Section
                            SettingsSection(title: "Danger Zone") {
                                DangerousSettingsRow(
                                    icon: "trash",
                                    title: "Delete Account",
                                    subtitle: "Permanently delete your account and all data",
                                    action: {
                                        showingDeleteConfirmation = true
                                    }
                                )
                            }
                            
                            // Account Info
                            VStack(spacing: 8) {
                                if let user = firebaseManager.currentUser {
                                    Text("Account created: \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.bulkShareTextMedium)
                                } else {
                                    Text("Loading account information...")
                                        .font(.caption)
                                        .foregroundColor(.bulkShareTextMedium)
                                        .italic()
                                }
                            }
                            .padding(.top, 20)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    handleDeleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data, groups, and plans will be permanently deleted.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingEmailDebug) {
                EmailDebugView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingAcknowledgments) {
                AcknowledgmentsView()
            }
        }
    }
    
    private func handleDeleteAccount() {
        isDeleting = true
        
        Task {
            let result = await firebaseManager.deleteAccount()
            
            DispatchQueue.main.async {
                self.isDeleting = false
                
                switch result {
                case .success:
                    // Account deleted successfully, user will be automatically signed out
                    // and redirected to login screen by RootView
                    break
                case .failure(let error):
                    self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProfileHeaderView: View {
    let userName: String
    let userEmail: String
    
    private var userInitials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image / Initials
            ZStack {
                Circle()
                    .fill(Color.bulkSharePrimary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Text(userInitials)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkSharePrimary)
            }
            
            // User Name
            VStack(spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
            }
        }
        .padding(.vertical)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.bulkShareTextDark)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.bulkSharePrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.bulkShareTextDark)
                
                if !value.isEmpty {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
            }
            
            Spacer()
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

struct DangerousSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.red)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.bulkShareTextLight)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct DeletingAccountView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                .scaleEffect(1.5)
            
            Text("Deleting account...")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(FirebaseManager.shared)
}
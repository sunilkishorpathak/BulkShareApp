//
//  CreateGroupView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  CreateGroupView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct CreateGroupView: View {
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedIcon: String = "👥"
    @State private var memberEmails: [String] = [""]
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    
    private let availableIcons = ["👨‍👩‍👧‍👦", "🏢", "🏘️", "👥", "🏠", "🌟", "💚", "🛒"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("🍃")
                                .font(.system(size: 50))
                                .frame(width: 80, height: 80)
                                .background(Color.bulkSharePrimary.opacity(0.1))
                                .cornerRadius(20)
                            
                            VStack(spacing: 4) {
                                Text("Create Group")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.bulkShareTextDark)
                                
                                Text("Start sharing with friends and family")
                                    .font(.subheadline)
                                    .foregroundColor(.bulkShareTextMedium)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        
                        // Group Details Form
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Group Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkShareTextDark)
                            
                            // Group Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Group Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                TextField("e.g., Sage Elite Family", text: $groupName)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                TextField("What's this group about?", text: $groupDescription, axis: .vertical)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .lineLimit(3, reservesSpace: true)
                            }
                            
                            // Icon Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Group Icon")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                    ForEach(availableIcons, id: \.self) { icon in
                                        Button(action: {
                                            selectedIcon = icon
                                        }) {
                                            Text(icon)
                                                .font(.title)
                                                .frame(width: 60, height: 60)
                                                .background(selectedIcon == icon ? Color.bulkSharePrimary.opacity(0.2) : Color.bulkShareBackground)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedIcon == icon ? Color.bulkSharePrimary : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        
                        // Add Members Form
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Invite Members")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                                
                                Spacer()
                                
                                Button(action: addMemberField) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.bulkSharePrimary)
                                        .font(.title3)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(memberEmails.indices, id: \.self) { index in
                                    HStack {
                                        TextField("member@email.com", text: $memberEmails[index])
                                            .textFieldStyle(BulkShareTextFieldStyle())
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                        
                                        if memberEmails.count > 1 {
                                            Button(action: {
                                                removeMemberField(at: index)
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.title3)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Text("Group invitations will be sent to these email addresses")
                                .font(.caption)
                                .foregroundColor(.bulkShareTextLight)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        
                        // Create Button
                        Button(action: handleCreateGroup) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Group")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isFormValid ? Color.bulkSharePrimary : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Group Created!" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !groupName.isEmpty && selectedIcon != ""
    }
    
    private func addMemberField() {
        memberEmails.append("")
    }
    
    private func removeMemberField(at index: Int) {
        if memberEmails.count > 1 {
            memberEmails.remove(at: index)
        }
    }
    
    private func handleCreateGroup() {
        guard isFormValid else {
            showAlert(title: "Invalid Form", message: "Please enter a group name")
            return
        }
        
        guard let currentUser = FirebaseManager.shared.currentUser else {
            showAlert(title: "Error", message: "Please sign in to create a group")
            return
        }
        
        isLoading = true
        
        Task {
            // Filter out empty emails
            let validEmails = memberEmails.filter { !$0.isEmpty && isValidEmail($0) }
            
            // Create the group object
            let group = Group(
                name: groupName,
                description: groupDescription,
                members: [currentUser.id], // Add current user as first member
                invitedEmails: validEmails, // Add invited emails
                icon: selectedIcon,
                adminId: currentUser.id
            )
            
            do {
                // Save group to Firestore
                let groupId = try await FirebaseManager.shared.createGroup(group)
                
                // Send invitation emails if there are valid emails
                var emailResult: Result<Void, EmailError>?
                if !validEmails.isEmpty {
                    emailResult = await EmailService.shared.sendGroupInvitations(
                        groupName: groupName,
                        inviterName: currentUser.name,
                        memberEmails: validEmails,
                        groupId: groupId
                    )
                }
                
                // Send in-app notifications to existing users
                print("🚀 Sending notifications to \(validEmails.count) emails: \(validEmails)")
                for email in validEmails {
                    do {
                        print("📱 Creating notification for email: \(email)")
                        try await NotificationManager.shared.createGroupInvitationNotification(
                            groupId: groupId,
                            groupName: groupName,
                            inviterUserId: currentUser.id,
                            inviterName: currentUser.name,
                            recipientEmail: email
                        )
                        print("✅ Successfully created notification for \(email)")
                    } catch {
                        print("❌ Failed to create notification for \(email): \(error)")
                        // Continue with other notifications even if one fails
                    }
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    let message: String
                    if validEmails.isEmpty {
                        message = "Group \"\(self.groupName)\" has been created!"
                    } else {
                        switch emailResult {
                        case .success:
                            message = "Group \"\(self.groupName)\" has been created and invitations sent to \(validEmails.count) members. Existing app users will receive notifications."
                        case .failure(let error):
                            message = "Group \"\(self.groupName)\" has been created, but failed to send some invitations: \(error.localizedDescription)"
                        case .none:
                            message = "Group \"\(self.groupName)\" has been created!"
                        }
                    }
                    
                    self.showAlert(
                        title: "Group Created!",
                        message: message
                    )
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Error",
                        message: "Failed to create group: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    CreateGroupView()
}
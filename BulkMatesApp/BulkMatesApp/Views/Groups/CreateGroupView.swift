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
    @State private var showingInviteSheet: Bool = false
    @State private var createdGroupInviteCode: String = ""
    @State private var createdGroupName: String = ""
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
                        
                        // Invite Members Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Invite Members")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkShareTextDark)

                            // Share Link Method (Primary)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "link.circle.fill")
                                        .foregroundColor(.bulkSharePrimary)
                                        .font(.title3)

                                    Text("Share Invite Link")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.bulkShareTextDark)
                                }

                                Text("After creating the group, you'll get a shareable invite link and code")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextMedium)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(Color.bulkSharePrimary.opacity(0.05))
                            .cornerRadius(12)

                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.bulkShareTextLight.opacity(0.3))
                                    .frame(height: 1)

                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextLight)
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(Color.bulkShareTextLight.opacity(0.3))
                                    .frame(height: 1)
                            }

                            // Email Invite Method (Secondary)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "envelope.circle.fill")
                                        .foregroundColor(.bulkShareTextMedium)
                                        .font(.title3)

                                    Text("Invite by Email (Optional)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
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

                                Text("Email invitations will be sent to these addresses")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextLight)
                            }
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
            .sheet(isPresented: $showingInviteSheet) {
                GroupInviteShareSheet(
                    groupName: createdGroupName,
                    inviteCode: createdGroupInviteCode,
                    onDismiss: { dismiss() }
                )
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

                    // Store invite code and group name for sharing
                    self.createdGroupInviteCode = group.inviteCode
                    self.createdGroupName = self.groupName

                    // Show invite sheet to share the code
                    self.showingInviteSheet = true
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

// MARK: - Group Invite Share Sheet
struct GroupInviteShareSheet: View {
    let groupName: String
    let inviteCode: String
    let onDismiss: () -> Void
    @State private var showCopiedConfirmation = false

    var shareMessage: String {
        "Join my BulkMates group '\(groupName)'!\n\nInvite Code: \(inviteCode)\n\nDownload BulkMates and enter this code to join."
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Success Icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.bulkShareSuccess.opacity(0.1))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.bulkShareSuccess)
                            }

                            VStack(spacing: 8) {
                                Text("Group Created!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.bulkShareTextDark)

                                Text(groupName)
                                    .font(.headline)
                                    .foregroundColor(.bulkShareTextMedium)
                            }
                        }
                        .padding(.top, 20)

                        // Invite Code Card
                        VStack(spacing: 20) {
                            Text("Share this code to invite members")
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextMedium)

                            // Large Invite Code Display
                            VStack(spacing: 12) {
                                Text("INVITE CODE")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextLight)
                                    .tracking(1)

                                Text(inviteCode)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.bulkSharePrimary)
                                    .tracking(4)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 20)
                                    .background(Color.bulkSharePrimary.opacity(0.08))
                                    .cornerRadius(16)
                            }

                            // Copy Button
                            Button(action: copyInviteCode) {
                                HStack {
                                    Image(systemName: showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                                    Text(showCopiedConfirmation ? "Copied!" : "Copy Code")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.bulkSharePrimary.opacity(0.1))
                                .foregroundColor(.bulkSharePrimary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // Share Options
                        VStack(spacing: 16) {
                            Text("Or share via")
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextLight)

                            // Share Button
                            ShareLink(item: shareMessage) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Invite")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.bulkSharePrimary)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.bulkShareInfo)
                                Text("How to share")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InstructionRow(number: "1", text: "Share the invite code via WhatsApp, Messages, or any app")
                                InstructionRow(number: "2", text: "Friends download BulkMates and sign up")
                                InstructionRow(number: "3", text: "They tap 'Join Group' and enter the code")
                                InstructionRow(number: "4", text: "Start planning together!")
                            }
                        }
                        .padding(20)
                        .background(Color.bulkShareInfo.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)

                        // Done Button
                        Button(action: onDismiss) {
                            Text("Done")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.bulkShareTextLight.opacity(0.2))
                                .foregroundColor(.bulkShareTextDark)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 30)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Invite Members")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = inviteCode
        showCopiedConfirmation = true

        // Reset confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedConfirmation = false
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.bulkSharePrimary)
                .clipShape(Circle())

            Text(text)
                .font(.caption)
                .foregroundColor(.bulkShareTextMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    CreateGroupView()
}
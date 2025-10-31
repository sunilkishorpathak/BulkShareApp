//
//  JoinGroupView.swift
//  BulkMatesApp
//
//  Created for joining groups via invite code
//

import SwiftUI

struct JoinGroupView: View {
    @State private var inviteCode: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var foundGroup: Group?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.bulkSharePrimary.opacity(0.1))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.bulkSharePrimary)
                            }

                            VStack(spacing: 8) {
                                Text("Join a Group")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.bulkShareTextDark)

                                Text("Enter the invite code to join")
                                    .font(.subheadline)
                                    .foregroundColor(.bulkShareTextMedium)
                            }
                        }
                        .padding(.top, 20)

                        // Invite Code Input
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Invite Code")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkShareTextDark)

                            // Code Input Field
                            TextField("ABC123", text: $inviteCode)
                                .textFieldStyle(BulkShareTextFieldStyle())
                                .autocapitalization(.allCharacters)
                                .autocorrectionDisabled()
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .onChange(of: inviteCode) { oldValue, newValue in
                                    // Limit to 6 characters and uppercase
                                    let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                    if filtered.count > 6 {
                                        inviteCode = String(filtered.prefix(6))
                                    } else {
                                        inviteCode = filtered
                                    }
                                }

                            Text("Enter the 6-character code shared with you")
                                .font(.caption)
                                .foregroundColor(.bulkShareTextLight)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        // Group Preview (if found)
                        if let group = foundGroup {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.bulkShareSuccess)
                                    Text("Group Found!")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.bulkShareTextDark)
                                }

                                HStack(spacing: 16) {
                                    Text(group.icon)
                                        .font(.system(size: 40))
                                        .frame(width: 60, height: 60)
                                        .background(Color.bulkSharePrimary.opacity(0.1))
                                        .cornerRadius(12)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(group.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.bulkShareTextDark)

                                        if !group.description.isEmpty {
                                            Text(group.description)
                                                .font(.caption)
                                                .foregroundColor(.bulkShareTextMedium)
                                                .lineLimit(2)
                                        }

                                        HStack(spacing: 4) {
                                            Image(systemName: "person.2.fill")
                                                .font(.caption)
                                            Text("\(group.memberCount) members")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.bulkShareTextLight)
                                    }

                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.bulkShareSuccess.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.bulkShareSuccess.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Action Buttons
                        if foundGroup == nil {
                            // Search Button
                            Button(action: searchGroup) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                        Text("Find Group")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(inviteCode.count == 6 ? Color.bulkSharePrimary : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(inviteCode.count != 6 || isLoading)
                            .padding(.horizontal)
                        } else {
                            // Join Button
                            Button(action: joinGroup) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                        Text("Join Group")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.bulkSharePrimary)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(isLoading)
                            .padding(.horizontal)
                        }

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.bulkShareInfo)
                                Text("How it works")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "Get the invite code from a group member")
                                BulletPoint(text: "Enter the 6-character code above")
                                BulletPoint(text: "Tap 'Find Group' to verify the code")
                                BulletPoint(text: "Review the group details and tap 'Join'")
                            }
                        }
                        .padding(20)
                        .background(Color.bulkShareInfo.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)

                        Spacer(minLength: 30)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Join Group")
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
                    if alertTitle == "Success!" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func searchGroup() {
        guard inviteCode.count == 6 else {
            showAlert(title: "Invalid Code", message: "Please enter a valid 6-character invite code")
            return
        }

        isLoading = true

        Task {
            do {
                let group = try await FirebaseManager.shared.findGroupByInviteCode(inviteCode)

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.foundGroup = group
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Not Found",
                        message: "No group found with code '\(self.inviteCode)'. Please check the code and try again."
                    )
                }
            }
        }
    }

    private func joinGroup() {
        guard let group = foundGroup,
              let currentUser = FirebaseManager.shared.currentUser else {
            showAlert(title: "Error", message: "Please sign in to join a group")
            return
        }

        // Check if already a member
        if group.members.contains(currentUser.id) {
            showAlert(title: "Already a Member", message: "You're already a member of this group!")
            return
        }

        isLoading = true

        Task {
            do {
                try await FirebaseManager.shared.joinGroupWithInviteCode(
                    groupId: group.id,
                    userId: currentUser.id
                )

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Success!",
                        message: "You've successfully joined '\(group.name)'! Start planning together."
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Error",
                        message: "Failed to join group: \(error.localizedDescription)"
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
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.caption)
                .foregroundColor(.bulkSharePrimary)
                .fontWeight(.bold)

            Text(text)
                .font(.caption)
                .foregroundColor(.bulkShareTextMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    JoinGroupView()
}

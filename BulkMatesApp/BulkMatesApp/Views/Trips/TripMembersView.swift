//
//  TripMembersView.swift
//  BulkMatesApp
//
//  Role management view for trips
//

import SwiftUI

struct TripMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var trip: Trip
    @State private var isLoading = false
    @State private var adminUsers: [User] = []
    @State private var viewerUsers: [User] = []
    @State private var showingRoleChangeAlert = false
    @State private var showingLastAdminAlert = false
    @State private var showingSelfDemoteAlert = false
    @State private var selectedUser: User?
    @State private var targetRole: TripRole?

    // MARK: - Initializer
    init(trip: Trip) {
        _trip = State(initialValue: trip)
    }

    private var currentUserId: String {
        FirebaseManager.shared.currentUser?.id ?? ""
    }

    private var currentUserRole: TripRole {
        trip.userRole(userId: currentUserId)
    }

    private var canManageRoles: Bool {
        return trip.canEditList(userId: currentUserId)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        TripMembersHeaderCard(
                            trip: trip,
                            adminCount: trip.adminIds.count,
                            viewerCount: trip.viewerIds.count
                        )

                        // Admins Section
                        MembersRoleSection(
                            role: .admin,
                            users: adminUsers,
                            trip: trip,
                            canManageRoles: canManageRoles,
                            currentUserId: currentUserId,
                            onRoleChange: { user, newRole in
                                handleRoleChange(user: user, newRole: newRole)
                            }
                        )

                        // Viewers Section
                        MembersRoleSection(
                            role: .viewer,
                            users: viewerUsers,
                            trip: trip,
                            canManageRoles: canManageRoles,
                            currentUserId: currentUserId,
                            onRoleChange: { user, newRole in
                                handleRoleChange(user: user, newRole: newRole)
                            }
                        )

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Plan Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            .alert("Remove Admin Access?", isPresented: $showingRoleChangeAlert) {
                Button("Cancel", role: .cancel) {
                    selectedUser = nil
                    targetRole = nil
                }
                Button("Remove Access", role: .destructive) {
                    confirmRoleChange()
                }
            } message: {
                if let user = selectedUser {
                    Text("\(user.name) will no longer be able to edit the list. They can still claim items and comment.")
                }
            }
            .alert("Cannot Remove Last Admin", isPresented: $showingLastAdminAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This plan must have at least one Admin. Promote someone else to Admin first.")
            }
            .alert("Demote Yourself?", isPresented: $showingSelfDemoteAlert) {
                Button("Cancel", role: .cancel) {
                    selectedUser = nil
                    targetRole = nil
                }
                Button("Continue", role: .destructive) {
                    confirmRoleChange()
                }
            } message: {
                Text("You won't be able to edit the list anymore. Continue?")
            }
            .onAppear {
                loadMembers()
            }
        }
    }

    private func loadMembers() {
        isLoading = true

        Task {
            do {
                // Load admin users
                var loadedAdmins: [User] = []
                for userId in trip.adminIds {
                    if let user = try? await FirebaseManager.shared.getUser(uid: userId) {
                        loadedAdmins.append(user)
                    }
                }

                // Load viewer users
                var loadedViewers: [User] = []
                for userId in trip.viewerIds {
                    if let user = try? await FirebaseManager.shared.getUser(uid: userId) {
                        loadedViewers.append(user)
                    }
                }

                DispatchQueue.main.async {
                    self.adminUsers = loadedAdmins
                    self.viewerUsers = loadedViewers
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("Error loading members: \(error)")
            }
        }
    }

    private func handleRoleChange(user: User, newRole: TripRole) {
        selectedUser = user
        targetRole = newRole

        // Check if demoting last admin
        if newRole == .viewer && trip.isLastAdmin(userId: user.id) {
            showingLastAdminAlert = true
            return
        }

        // Check if demoting self
        if newRole == .viewer && user.id == currentUserId {
            showingSelfDemoteAlert = true
            return
        }

        // Demoting another admin requires confirmation
        if newRole == .viewer && trip.userRole(userId: user.id) == .admin {
            showingRoleChangeAlert = true
            return
        }

        // Promoting viewer to admin - do directly
        confirmRoleChange()
    }

    private func confirmRoleChange() {
        guard let user = selectedUser, let newRole = targetRole else { return }

        isLoading = true

        Task {
            do {
                // Update trip object
                if newRole == .admin {
                    trip.promoteToAdmin(userId: user.id)
                } else {
                    trip.demoteToViewer(userId: user.id)
                }

                // TODO: Save to Firebase
                // try await FirebaseManager.shared.updateTrip(trip)

                // Reload members
                await loadMembers()

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.selectedUser = nil
                    self.targetRole = nil
                }

                print("Role changed for \(user.name) to \(newRole.displayName)")

            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("Error changing role: \(error)")
            }
        }
    }
}

// MARK: - Trip Members Header Card
struct TripMembersHeaderCard: View {
    let trip: Trip
    let adminCount: Int
    let viewerCount: Int

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Text(trip.tripType.icon)
                .font(.system(size: 50))
                .frame(width: 80, height: 80)
                .background(trip.tripType.accentColor.opacity(0.1))
                .cornerRadius(20)

            // Trip info
            VStack(spacing: 8) {
                Text("Member Roles")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.bulkShareTextDark)

                Text("\(trip.totalMemberCount) members")
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
            }

            // Role summary
            HStack(spacing: 20) {
                RoleSummaryBadge(
                    role: .admin,
                    count: adminCount
                )

                RoleSummaryBadge(
                    role: .viewer,
                    count: viewerCount
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Role Summary Badge
struct RoleSummaryBadge: View {
    let role: TripRole
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(role.icon)
                .font(.title2)

            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.bulkShareTextDark)

            Text(role.displayName)
                .font(.caption)
                .foregroundColor(.bulkShareTextMedium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(role.accentColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Members Role Section
struct MembersRoleSection: View {
    let role: TripRole
    let users: [User]
    let trip: Trip
    let canManageRoles: Bool
    let currentUserId: String
    let onRoleChange: (User, TripRole) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("\(role.icon) \(role.displayName)s (\(users.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)

                Spacer()
            }

            if users.isEmpty {
                EmptyRoleSectionCard(role: role)
            } else {
                VStack(spacing: 12) {
                    ForEach(users, id: \.id) { user in
                        MemberRoleRow(
                            user: user,
                            role: role,
                            trip: trip,
                            canManageRoles: canManageRoles,
                            isCurrentUser: user.id == currentUserId,
                            onRoleChange: { newRole in
                                onRoleChange(user, newRole)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Empty Role Section Card
struct EmptyRoleSectionCard: View {
    let role: TripRole

    var body: some View {
        VStack(spacing: 12) {
            Text(role.icon)
                .font(.system(size: 40))
                .foregroundColor(.bulkShareTextLight)

            Text("No \(role.displayName)s yet")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

// MARK: - Member Role Row
struct MemberRoleRow: View {
    let user: User
    let role: TripRole
    let trip: Trip
    let canManageRoles: Bool
    let isCurrentUser: Bool
    let onRoleChange: (TripRole) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Text(user.initials)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(role.accentColor)
                .cornerRadius(22)

            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)

                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.bulkSharePrimary)
                    }
                }

                if trip.isCreator(userId: user.id) {
                    Text("Plan Creator")
                        .font(.caption)
                        .foregroundColor(.bulkShareWarning)
                }
            }

            Spacer()

            // Role change button
            if canManageRoles {
                RoleToggleButton(
                    currentRole: role,
                    onToggle: {
                        let newRole: TripRole = role == .admin ? .viewer : .admin
                        onRoleChange(newRole)
                    }
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Role Toggle Button
struct RoleToggleButton: View {
    let currentRole: TripRole
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                if currentRole == .admin {
                    Image(systemName: "arrow.down.circle")
                    Text("Viewer")
                } else {
                    Image(systemName: "arrow.up.circle")
                    Text("Admin")
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(currentRole == .admin ? Color.orange : Color.bulkSharePrimary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    TripMembersView(
        trip: Trip(
            groupId: "group1",
            shopperId: "user1",
            tripType: .bulkShopping,
            store: .costco,
            scheduledDate: Date(),
            creatorId: "user1",
            adminIds: ["user1", "user2"],
            viewerIds: ["user3", "user4", "user5"]
        )
    )
}

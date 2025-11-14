//
//  GroupDetailView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @State private var activeTrips: [Trip] = Trip.sampleTrips
    @State private var showingSettings = false
    @State private var showingTripTypeSelection = false
    @State private var showingCreateTrip = false
    @State private var selectedTripType: TripType = .shopping
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Group Header
                GroupHeaderView(group: group)
                
                // Members Section
                GroupMembersSection(group: group)
                
                // Active Trips Section
                ActiveTripsSection(trips: activeTrips, group: group)
                
                // Quick Actions Section
                QuickActionsSection(group: group, onCreateTrip: {
                    showingTripTypeSelection = true
                })
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.bulkSharePrimary)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            GroupSettingsView(group: group)
        }
        .sheet(isPresented: $showingTripTypeSelection) {
            TripTypeSelectionView(group: group) { tripType in
                selectedTripType = tripType
                showingTripTypeSelection = false
                // Show CreateTripView after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingCreateTrip = true
                }
            }
        }
        .sheet(isPresented: $showingCreateTrip) {
            NavigationView {
                CreateTripView(group: group, tripType: selectedTripType)
            }
        }
    }
}

struct GroupHeaderView: View {
    let group: Group
    
    var body: some View {
        VStack(spacing: 16) {
            // Group Icon
            Text(group.icon)
                .font(.system(size: 60))
                .frame(width: 100, height: 100)
                .background(Color.bulkSharePrimary.opacity(0.1))
                .cornerRadius(20)
            
            // Group Info
            VStack(spacing: 8) {
                Text(group.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.bulkShareTextDark)
                
                if !group.description.isEmpty {
                    Text(group.description)
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 20) {
                    Label("\(group.memberCount) members", systemImage: "person.3.fill")
                    Label("Created \(group.createdAt, style: .relative)", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(.bulkShareTextLight)
            }
            
            // Group Stats
            GroupStatCard(title: "Active Plans", value: "2", icon: "cart.fill", color: .bulkSharePrimary)
                .frame(maxWidth: 200)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct GroupStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.bulkShareTextDark)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.bulkShareTextMedium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct GroupMembersSection: View {
    let group: Group
    @State private var showingAllMembers = false
    @State private var showingInviteMembers = false
    @State private var groupMembers: [User] = []
    @State private var isLoadingMembers = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("👥 Members (\(group.memberCount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                if group.memberCount > 3 {
                    Button("View All") {
                        showingAllMembers = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            
            // Member List
            VStack(spacing: 12) {
                // Show actual members
                ForEach(groupMembers, id: \.id) { user in
                    MemberRow(user: user, group: group, isActualMember: true)
                }
                
                // Show invited emails
                ForEach(group.invitedEmails, id: \.self) { email in
                    InvitedEmailRow(email: email)
                }
            }
            
            // Add Member Button
            Button(action: {
                showingInviteMembers = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.bulkSharePrimary)
                    
                    Text("Invite Members")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkSharePrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                .padding()
                .background(Color.bulkSharePrimary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .sheet(isPresented: $showingAllMembers) {
            AllMembersView(group: group)
        }
        .sheet(isPresented: $showingInviteMembers) {
            InviteMembersView(group: group)
        }
        .onAppear {
            loadGroupMembers()
        }
    }
    
    private func loadGroupMembers() {
        isLoadingMembers = true
        
        Task {
            do {
                // Load actual users from Firestore for the member IDs
                var members: [User] = []
                for memberId in group.members {
                    if let user = try? await FirebaseManager.shared.getUser(uid: memberId) {
                        members.append(user)
                    }
                }
                
                DispatchQueue.main.async {
                    self.groupMembers = members
                    self.isLoadingMembers = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingMembers = false
                }
            }
        }
    }
}

struct ActiveTripsSection: View {
    let trips: [Trip]
    let group: Group
    @State private var showingTripTypeSelection = false
    @State private var showingCreateTrip = false
    @State private var showingAllTrips = false
    @State private var selectedTripType: TripType = .shopping

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🛒 Active Plans (\(trips.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)

                Spacer()

                Button("Create Plan") {
                    showingTripTypeSelection = true
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bulkSharePrimary)
                .cornerRadius(8)
            }
            
            if trips.isEmpty {
                EmptyTripsCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(trips.prefix(3)) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            EnhancedTripCard(trip: trip)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if trips.count > 3 {
                        Button("View All Plans (\(trips.count))") {
                            showingAllTrips = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.bulkSharePrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.bulkSharePrimary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .sheet(isPresented: $showingTripTypeSelection) {
            TripTypeSelectionView(group: group) { tripType in
                selectedTripType = tripType
                showingTripTypeSelection = false
                // Show CreateTripView after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingCreateTrip = true
                }
            }
        }
        .sheet(isPresented: $showingCreateTrip) {
            NavigationView {
                CreateTripView(group: group, tripType: selectedTripType)
            }
        }
        .sheet(isPresented: $showingAllTrips) {
            AllTripsView(groupId: group.id)
        }
    }
}

struct EmptyTripsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.bulkShareTextLight)
            
            VStack(spacing: 8) {
                Text("No Active Plans")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)

                Text("Create a plan to start bulk sharing with your group")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

struct EnhancedTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text(trip.tripType.icon)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.bulkShareTextDark)

                        Text(trip.scheduledDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(trip.totalEstimatedCost, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkSharePrimary)
                    
                    Badge(text: trip.status.displayName, color: Color(hex: trip.status.color))
                }
            }
            
            // Items Preview
            HStack {
                ForEach(trip.items.prefix(3), id: \.id) { item in
                    Text(item.category.icon)
                        .font(.caption)
                        .frame(width: 24, height: 24)
                        .background(Color.bulkSharePrimary.opacity(0.1))
                        .cornerRadius(6)
                }
                
                if trip.items.count > 3 {
                    Text("+\(trip.items.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.bulkShareTextMedium)
                        .frame(width: 24, height: 24)
                        .background(Color.bulkShareBackground)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Text("\(trip.items.count) items")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
            
            // Footer
            HStack {
                Label("\(trip.participantCount) joined", systemImage: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.bulkShareInfo)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(trip.scheduledDate, style: .time)
                        .font(.caption)
                }
                .foregroundColor(.bulkShareTextLight)
            }
        }
        .padding()
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

struct QuickActionsSection: View {
    let group: Group
    let onCreateTrip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    icon: "cart.badge.plus",
                    title: "Create Plan",
                    subtitle: "Plan a new activity",
                    color: .bulkSharePrimary,
                    action: onCreateTrip
                )
                
                QuickActionCard(
                    icon: "person.badge.plus",
                    title: "Invite Members",
                    subtitle: "Add family & friends",
                    color: .bulkShareInfo
                ) {
                    // Invite members
                }
                
                QuickActionCard(
                    icon: "chart.bar.fill",
                    title: "View Analytics",
                    subtitle: "See group savings",
                    color: .bulkShareSuccess
                ) {
                    // View analytics
                }
                
                QuickActionCard(
                    icon: "gear",
                    title: "Group Settings",
                    subtitle: "Manage preferences",
                    color: .bulkShareWarning
                ) {
                    // Group settings
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.bulkShareBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Placeholder views for navigation
struct AllMembersView: View {
    let group: Group
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("All Members")
                    .font(.title)
                
                Text("Coming Soon!")
                    .foregroundColor(.bulkShareTextMedium)
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AllTripsView: View {
    let groupId: String
    @Environment(\.dismiss) private var dismiss
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading plans...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.bulkShareTextMedium)
                        Text("Error loading plans")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if trips.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.bulkShareTextMedium)
                        Text("No Plans Yet")
                            .font(.headline)
                        Text("Create your first group plan to get started")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(trips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    EnhancedTripCard(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("All Plans (\(trips.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.bulkSharePrimary)
                }
            }
            .task {
                await loadAllTrips()
            }
        }
    }

    private func loadAllTrips() async {
        isLoading = true
        defer { isLoading = false }

        do {
            trips = try await FirebaseManager.shared.getGroupTrips(groupId: groupId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Placeholder for settings
struct GroupSettingsView: View {
    let group: Group
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingLeaveConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingComingSoonAlert = false
    @State private var comingSoonFeature = ""

    private var isAdmin: Bool {
        guard let currentUser = FirebaseManager.shared.currentUser else { return false }
        return group.adminId == currentUser.id
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Group Settings Content
                    VStack(spacing: 16) {
                        Text("Group Settings")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                            SettingsRow(icon: "pencil", title: "Edit Group Info", action: {})
                            SettingsRow(icon: "person.badge.plus", title: "Manage Members (Coming Soon)", isDisabled: true, action: {
                                comingSoonFeature = "Member Management"
                                showingComingSoonAlert = true
                            })
                            SettingsRow(icon: "bell", title: "Notifications (Coming Soon)", isDisabled: true, action: {
                                comingSoonFeature = "Notification Settings"
                                showingComingSoonAlert = true
                            })
                            SettingsRow(icon: "chart.bar", title: "Group Analytics (Coming Soon)", isDisabled: true, action: {
                                comingSoonFeature = "Group Analytics"
                                showingComingSoonAlert = true
                            })
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // Danger Zone
                        VStack(spacing: 12) {
                            Text("Danger Zone")
                                .font(.headline)
                                .foregroundColor(.red)

                            if isAdmin {
                                SettingsRow(icon: "trash.fill", title: "Delete Group", textColor: .red, showChevron: false, action: {
                                    showingDeleteConfirmation = true
                                })
                            } else {
                                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Leave Group", textColor: .red, showChevron: false, action: {
                                    showingLeaveConfirmation = true
                                })
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.bulkSharePrimary)
                }
            }
            .alert("Delete Group?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteGroup()
                }
            } message: {
                Text("Are you sure you want to delete this group? This will remove all plans and cannot be undone.")
            }
            .alert("Leave Group?", isPresented: $showingLeaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    leaveGroup()
                }
            } message: {
                Text("Are you sure you want to leave '\(group.name)'? You'll need an invite to rejoin.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .alert("Coming Soon!", isPresented: $showingComingSoonAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(comingSoonFeature) will be available in a future update.")
            }
            .overlay {
                if isDeleting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Deleting group...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    private func deleteGroup() {
        isDeleting = true

        Task {
            do {
                try await FirebaseManager.shared.deleteGroup(groupId: group.id)
                DispatchQueue.main.async {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isDeleting = false
                    errorMessage = "Failed to delete group: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func leaveGroup() {
        isDeleting = true

        Task {
            do {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                try await FirebaseManager.shared.leaveGroup(groupId: group.id, userId: currentUser.id)
                DispatchQueue.main.async {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isDeleting = false
                    errorMessage = "Failed to leave group: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var textColor: Color = .bulkShareTextDark
    var showChevron: Bool = true
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }
            .padding()
            .background(Color.bulkShareBackground)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Helper Views for Members

struct MemberRow: View {
    let user: User
    let group: Group
    let isActualMember: Bool

    var body: some View {
        HStack {
            // Profile Picture
            ProfileImageView(user: user, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)

                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if user.id == group.adminId {
                    Badge(text: "Admin", color: .bulkShareInfo)
                }

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isActualMember ? Color.bulkShareSuccess : Color.bulkShareWarning)
                        .frame(width: 8, height: 8)
                    Text(isActualMember ? "Active" : "Invited")
                        .font(.caption2)
                        .foregroundColor(isActualMember ? .bulkShareSuccess : .bulkShareWarning)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct InvitedEmailRow: View {
    let email: String
    
    var body: some View {
        HStack {
            // Avatar placeholder
            Text("📧")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Color.bulkShareWarning.opacity(0.2))
                .cornerRadius(22)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Invited")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)
                
                Text(email)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Badge(text: "Pending", color: .bulkShareWarning)
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.bulkShareWarning)
                        .frame(width: 8, height: 8)
                    Text("Invited")
                        .font(.caption2)
                        .foregroundColor(.bulkShareWarning)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct InviteMembersView: View {
    let group: Group
    @State private var memberEmails: [String] = [""]
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text(group.icon)
                        .font(.system(size: 50))
                        .frame(width: 80, height: 80)
                        .background(Color.bulkSharePrimary.opacity(0.1))
                        .cornerRadius(20)
                    
                    VStack(spacing: 4) {
                        Text("Invite Members")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.bulkShareTextDark)
                        
                        Text("Add more people to \(group.name)")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                
                // Add Members Form
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Email Addresses")
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
                    
                    Text("Invitations will be sent to these email addresses")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                
                // Send Invitations Button
                Button(action: handleSendInvitations) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Invitations")
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
                
                Spacer()
            }
            .padding()
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("Invite Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bulkSharePrimary)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Invitations Sent!" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        let validEmails = memberEmails.filter { !$0.isEmpty && isValidEmail($0) }
        return !validEmails.isEmpty
    }
    
    private func addMemberField() {
        memberEmails.append("")
    }
    
    private func removeMemberField(at index: Int) {
        if memberEmails.count > 1 {
            memberEmails.remove(at: index)
        }
    }
    
    private func handleSendInvitations() {
        let validEmails = memberEmails.filter { !$0.isEmpty && isValidEmail($0) }
        
        guard !validEmails.isEmpty else {
            showAlert(title: "Invalid Emails", message: "Please enter at least one valid email address")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Update group with new invited emails
                let updatedGroup = Group(
                    id: group.id,
                    name: group.name,
                    description: group.description,
                    members: group.members,
                    invitedEmails: group.invitedEmails + validEmails,
                    icon: group.icon,
                    createdAt: group.createdAt,
                    adminId: group.adminId,
                    isActive: group.isActive
                )
                
                // Update group in Firestore
                try await FirebaseManager.shared.updateGroup(updatedGroup)
                
                // Create notifications for invited users
                let currentUser = FirebaseManager.shared.currentUser
                let inviterName = currentUser?.name ?? "Someone"
                let inviterUserId = currentUser?.id ?? ""
                
                var notificationResults: [Result<Void, Error>] = []
                
                for email in validEmails {
                    do {
                        try await NotificationManager.shared.createGroupInvitationNotification(
                            groupId: group.id,
                            groupName: group.name,
                            inviterUserId: inviterUserId,
                            inviterName: inviterName,
                            recipientEmail: email
                        )
                        notificationResults.append(.success(()))
                    } catch {
                        notificationResults.append(.failure(error))
                    }
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    let successCount = notificationResults.filter { if case .success = $0 { return true }; return false }.count
                    let failureCount = validEmails.count - successCount
                    
                    if failureCount == 0 {
                        self.showAlert(
                            title: "Invitations Sent!",
                            message: "Group updated and notifications sent to \(successCount) members. They'll see the invitation when they open the app."
                        )
                    } else {
                        self.showAlert(
                            title: "Partially Successful",
                            message: "Group updated and \(successCount) notifications sent. \(failureCount) users don't have accounts yet."
                        )
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Error",
                        message: "Failed to update group: \(error.localizedDescription)"
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
    NavigationView {
        GroupDetailView(group: Group.sampleGroups[0])
    }
}

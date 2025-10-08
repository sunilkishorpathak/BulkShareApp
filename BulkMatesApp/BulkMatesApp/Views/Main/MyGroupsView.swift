//
//  MyGroupsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct MyGroupsView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var userGroups: [Group] = []
    @State private var isLoading = true
    @State private var showingCreateGroup = false
    @State private var showingProfile = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                if isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header Stats
                            StatsHeaderView(userGroups: userGroups)
                            
                            // Groups List
                            if userGroups.isEmpty {
                                EmptyGroupsView()
                            } else {
                                ForEach(userGroups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupCard(group: group)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            Spacer(minLength: 100) // Space for floating button
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        await loadUserGroups()
                    }
                }
                
                // Floating Create Button
                FloatingCreateButton {
                    showingCreateGroup = true
                }
            }
            .navigationTitle("My Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingProfile = true
                        }) {
                            Label("Profile & Settings", systemImage: "person.circle")
                        }
                        
                        Button(action: {
                            Task { await loadUserGroups() }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            handleSignOut()
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.bulkSharePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showingProfile) {
                UserProfileView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                Task { await loadUserGroups() }
            }
            .onChange(of: firebaseManager.currentUser) { _ in
                Task { await loadUserGroups() }
            }
        }
    }
    
    @MainActor
    private func loadUserGroups() async {
        guard firebaseManager.currentUser != nil else {
            print("⚠️ MyGroupsView: No current user available, skipping group load")
            isLoading = false
            return
        }
        
        print("🏠 MyGroupsView: Loading groups for user \(firebaseManager.currentUser?.email ?? "unknown")")
        isLoading = true
        
        do {
            let groups = try await firebaseManager.getUserGroups()
            print("✅ MyGroupsView: Loaded \(groups.count) groups")
            self.userGroups = groups
            self.isLoading = false
        } catch {
            print("❌ MyGroupsView: Failed to load groups: \(error)")
            self.isLoading = false
            self.errorMessage = "Failed to load groups: \(error.localizedDescription)"
            self.showingError = true
        }
    }
    
    private func handleSignOut() {
        let result = firebaseManager.signOut()
        switch result {
        case .success:
            // Navigation handled by RootView
            break
        case .failure(let error):
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                .scaleEffect(1.5)
            
            Text("Loading your groups...")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
        }
    }
}

struct StatsHeaderView: View {
    let userGroups: [Group]
    
    private var activeGroups: Int {
        userGroups.filter { $0.isActive }.count
    }
    
    private var totalMembers: Int {
        userGroups.reduce(0) { $0 + $1.memberCount }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Groups",
                value: "\(userGroups.count)",
                icon: "person.3.fill",
                color: .bulkSharePrimary
            )
            
            StatCard(
                title: "Active",
                value: "\(activeGroups)",
                icon: "clock.fill",
                color: .bulkShareSuccess
            )
            
            StatCard(
                title: "Members",
                value: "\(totalMembers)",
                icon: "person.2.fill",
                color: .bulkShareInfo
            )
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.bulkShareTextDark)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.bulkShareTextMedium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GroupCard: View {
    let group: Group
    @State private var groupTrips: [Trip] = []
    @State private var isLoadingTrips = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Group Icon
                Text(group.icon)
                    .font(.title)
                    .frame(width: 50, height: 50)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("\(group.memberCount) members")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                // Status Badge
                VStack(spacing: 4) {
                    if group.isActive {
                        Badge(text: "Active", color: .bulkShareSuccess)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }
            
            // Description
            if !group.description.isEmpty {
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
                    .lineLimit(2)
            }
            
            // Footer with Trip Info
            HStack {
                if isLoadingTrips {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bulkShareInfo))
                            .scaleEffect(0.8)
                        Text("Loading trips...")
                            .font(.caption)
                            .foregroundColor(.bulkShareInfo)
                    }
                } else {
                    Label("\(groupTrips.count) active trips", systemImage: "cart.fill")
                        .font(.caption)
                        .foregroundColor(.bulkShareInfo)
                }
                
                Spacer()
                
                Text("Updated \(group.createdAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .onAppear {
            loadGroupTrips()
        }
    }
    
    private func loadGroupTrips() {
        isLoadingTrips = true
        
        Task {
            do {
                let trips = try await FirebaseManager.shared.getGroupTrips(groupId: group.id)
                DispatchQueue.main.async {
                    self.groupTrips = trips.filter { $0.status == .planned || $0.status == .inProgress }
                    self.isLoadingTrips = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingTrips = false
                }
            }
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

struct EmptyGroupsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.bulkShareTextLight)
            
            VStack(spacing: 8) {
                Text("No Groups Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Text("Create your first group or join existing ones to start bulk sharing")
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Text("Get started by:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.bulkSharePrimary)
                        Text("Creating a new group")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundColor(.bulkShareInfo)
                        Text("Browsing existing groups")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                    }
                    
                    HStack {
                        Image(systemName: "person.badge.plus.fill")
                            .foregroundColor(.bulkShareSuccess)
                        Text("Accepting group invitations")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                    }
                }
            }
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct FloatingCreateButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Create")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.bulkSharePrimary)
                    .cornerRadius(25)
                    .shadow(color: Color.bulkSharePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    MyGroupsView()
        .environmentObject(FirebaseManager.shared)
}

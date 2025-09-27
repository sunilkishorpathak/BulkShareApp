//
//  MyGroupsView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  MyGroupsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct MyGroupsView: View {
    @State private var userGroups: [Group] = Group.sampleGroups
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header Stats
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Groups",
                                value: "\(userGroups.count)",
                                icon: "person.3.fill",
                                color: .bulkSharePrimary
                            )
                            
                            StatCard(
                                title: "Active",
                                value: "\(userGroups.filter { $0.isActive }.count)",
                                icon: "clock.fill",
                                color: .bulkShareSuccess
                            )
                            
                            StatCard(
                                title: "Members",
                                value: "\(userGroups.reduce(0) { $0 + $1.memberCount })",
                                icon: "person.2.fill",
                                color: .bulkShareInfo
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
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
                
                // Floating Create Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingCreateGroup = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.bulkSharePrimary)
                                .clipShape(Circle())
                                .shadow(color: Color.bulkSharePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Refresh groups
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.bulkSharePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
    }
}

// MARK: - Supporting Views

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
            
            // Footer
            HStack {
                Label("2 active trips", systemImage: "cart.fill")
                    .font(.caption)
                    .foregroundColor(.bulkShareInfo)
                
                Spacer()
                
                Text("Updated 2h ago")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
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
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    MyGroupsView()
}
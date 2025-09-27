//
//  GroupDetailView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Group Header
                GroupHeaderView(group: group)
                
                // Members Section
                GroupMembersSection(group: group)
                
                // Active Trips Section
                ActiveTripsSection(trips: activeTrips)
                
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
                
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    Label("\(group.memberCount) members", systemImage: "person.3.fill")
                    Label("Created \(group.createdAt, style: .relative)", systemImage: "calendar")
                }
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

struct GroupMembersSection: View {
    let group: Group
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("👥 Members (\(group.memberCount))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all members
                }
                .font(.subheadline)
                .foregroundColor(.bulkSharePrimary)
            }
            
            // Sample Members
            VStack(spacing: 12) {
                ForEach(User.sampleUsers.prefix(3), id: \.id) { user in
                    HStack {
                        // Avatar
                        Text(user.initials)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.bulkSharePrimary)
                            .cornerRadius(20)
                        
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
                        
                        if user.id == group.adminId {
                            Badge(text: "Admin", color: .bulkShareInfo)
                        }
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

struct ActiveTripsSection: View {
    let trips: [Trip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🛒 Active Trips (\(trips.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                Button("Create Trip") {
                    // Navigate to create trip
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bulkSharePrimary)
                .cornerRadius(8)
            }
            
            if trips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart")
                        .font(.title)
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No active trips")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(trips.prefix(3)) { trip in
                        TripCard(trip: trip)
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

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(trip.store.icon) \(trip.store.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)
                
                Text(trip.scheduledDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(trip.items.count) items")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
                
                Text("$\(trip.totalEstimatedCost, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkSharePrimary)
            }
        }
        .padding()
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

// Placeholder for settings
struct GroupSettingsView: View {
    let group: Group
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Group Settings")
                    .font(.title)
                
                Text("Coming Soon!")
                    .foregroundColor(.bulkShareTextMedium)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: Group.sampleGroups[0])
    }
}
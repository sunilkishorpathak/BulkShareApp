//
//  MyTripsView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  MyTripsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct MyTripsView: View {
    @State private var selectedTab: TripTab = .upcoming
    @State private var upcomingTrips: [Trip] = []
    @State private var pastTrips: [Trip] = []
    @State private var hostingTrips: [Trip] = []
    @State private var isLoadingTrips = false
    @State private var showingTripFlow = false
    @State private var tripFlowState: TripFlowState = .groupSelection
    @State private var selectedGroup: Group?
    
    enum TripFlowState {
        case groupSelection
        case createTrip(Group)
    }
    
    enum TripTab: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case hosting = "Hosting"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    TripTabBar(selectedTab: $selectedTab)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        // Upcoming Trips
                        UpcomingTripsView(trips: upcomingTrips)
                            .tag(TripTab.upcoming)
                        
                        // Past Trips
                        PastTripsView(trips: pastTrips)
                            .tag(TripTab.past)
                        
                        // Hosting Trips
                        HostingTripsView(trips: hostingTrips)
                            .tag(TripTab.hosting)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .background(Color.bulkShareBackground.ignoresSafeArea())
                
                // Floating Create Trip Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingCreateTripButton {
                            tripFlowState = .groupSelection
                            showingTripFlow = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTripFlow) {
                switch tripFlowState {
                case .groupSelection:
                    GroupSelectionView { group in
                        tripFlowState = .createTrip(group)
                    }
                case .createTrip(let group):
                    CreateTripView(group: group)
                }
            }
            .onAppear {
                loadUserTrips()
            }
            .refreshable {
                loadUserTrips()
            }
        }
    }
    
    private func loadUserTrips() {
        isLoadingTrips = true
        
        Task {
            do {
                let trips = try await FirebaseManager.shared.getUserTrips()
                
                DispatchQueue.main.async {
                    // Filter trips by category
                    let now = Date()
                    let currentUserId = FirebaseManager.shared.currentUser?.id ?? ""
                    
                    self.upcomingTrips = trips.filter { trip in
                        trip.scheduledDate > now && trip.status == .planned
                    }
                    
                    self.pastTrips = trips.filter { trip in
                        trip.scheduledDate <= now || trip.status == .completed
                    }
                    
                    self.hostingTrips = trips.filter { trip in
                        trip.shopperId == currentUserId && trip.status == .planned
                    }
                    
                    self.isLoadingTrips = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingTrips = false
                    print("Error loading trips: \(error)")
                }
            }
        }
    }
}

struct TripTabBar: View {
    @Binding var selectedTab: MyTripsView.TripTab
    
    var body: some View {
        HStack {
            ForEach(MyTripsView.TripTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .medium)
                            .foregroundColor(selectedTab == tab ? .bulkSharePrimary : .bulkShareTextMedium)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .bulkSharePrimary : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color.white)
    }
}

struct UpcomingTripsView: View {
    let trips: [Trip]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if trips.isEmpty {
                    EmptyTripsView(
                        icon: "calendar.badge.plus",
                        title: "No Upcoming Trips",
                        subtitle: "Join or create trips to start bulk sharing"
                    )
                } else {
                    ForEach(trips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            UpcomingTripCard(trip: trip)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
    }
}

struct PastTripsView: View {
    let trips: [Trip]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if trips.isEmpty {
                    EmptyTripsView(
                        icon: "clock",
                        title: "No Past Trips",
                        subtitle: "Your completed trips will appear here"
                    )
                } else {
                    ForEach(trips) { trip in
                        PastTripCard(trip: trip)
                    }
                }
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
    }
}

struct HostingTripsView: View {
    let trips: [Trip]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if trips.isEmpty {
                    EmptyTripsView(
                        icon: "person.badge.plus",
                        title: "No Hosting Trips",
                        subtitle: "Create a trip to start hosting for your group"
                    )
                } else {
                    ForEach(trips) { trip in
                        HostingTripCard(trip: trip)
                    }
                }
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
    }
}

struct UpcomingTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(trip.store.icon) \(trip.store.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(trip.scheduledDate, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkSharePrimary)
                    
                    Text(trip.scheduledDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }
            
            // Items
            Text("\(trip.items.count) items • $\(trip.totalEstimatedCost, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
            
            // Status
            HStack {
                Label("\(trip.participantCount) joined", systemImage: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.bulkShareInfo)
                
                Spacer()
                
                Badge(text: "Upcoming", color: .bulkSharePrimary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct PastTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(trip.store.icon) \(trip.store.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                Badge(text: "Completed", color: .bulkShareSuccess)
            }
            
            Text(trip.scheduledDate, style: .date)
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
            
            HStack {
                Text("$\(trip.totalEstimatedCost, specifier: "%.2f") saved")
                    .font(.subheadline)
                    .foregroundColor(.bulkShareSuccess)
                
                Spacer()
                
                Button("Rate Experience") {
                    // Rate trip
                }
                .font(.caption)
                .foregroundColor(.bulkSharePrimary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct HostingTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(trip.store.icon) \(trip.store.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                Badge(text: "Hosting", color: .bulkShareWarning)
            }
            
            Text(trip.scheduledDate, style: .relative)
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
            
            HStack {
                Text("\(trip.participantCount) participants")
                    .font(.subheadline)
                    .foregroundColor(.bulkShareInfo)
                
                Spacer()
                
                Button("Manage") {
                    // Manage trip
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.bulkSharePrimary)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct EmptyTripsView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.bulkShareTextLight)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Text(subtitle)
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

struct FloatingCreateTripButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Create Trip")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.bulkSharePrimary, Color.bulkShareSecondary]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: Color.bulkSharePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: true)
    }
}

struct GroupSelectionView: View {
    let onGroupSelected: (Group) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var availableGroups: [Group] = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Select a Group")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("Choose which group to create a trip for")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Groups List
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                            .scaleEffect(1.2)
                        Text("Loading your groups...")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if availableGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.bulkShareTextLight)
                        
                        Text("No Groups Available")
                            .font(.headline)
                            .foregroundColor(.bulkShareTextDark)
                        
                        Text("Create a group first to start planning trips")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(availableGroups) { group in
                                GroupSelectionCard(group: group) {
                                    onGroupSelected(group)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("Create Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadUserGroups()
            }
        }
    }
    
    private func loadUserGroups() {
        isLoading = true
        
        Task {
            do {
                let groups = try await FirebaseManager.shared.getUserGroups()
                DispatchQueue.main.async {
                    self.availableGroups = groups
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to load groups: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
}

struct GroupSelectionCard: View {
    let group: Group
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Group Icon
                Text(group.icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(12)
                
                // Group Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("\(group.memberCount) members")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    if !group.description.isEmpty {
                        Text(group.description)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextLight)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MyTripsView()
}
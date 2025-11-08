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
    @State private var selectedTripType: TripTypeFilter = .all
    @State private var upcomingTrips: [Trip] = []
    @State private var pastTrips: [Trip] = []
    @State private var isLoadingTrips = false
    @State private var showingTripFlow = false
    @State private var tripFlowState: TripFlowState = .groupSelection
    @State private var selectedGroup: Group?

    enum TripTypeFilter: String, CaseIterable {
        case all = "All Plans"
        case shopping = "Shopping"
        case events = "Events"
        case trips = "Trips"

        var tripType: TripType? {
            switch self {
            case .all: return nil
            case .shopping: return .shopping
            case .events: return .events
            case .trips: return .trips
            }
        }

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .shopping: return "cart.fill"
            case .events: return "party.popper.fill"
            case .trips: return "figure.hiking"
            }
        }
    }
    
    enum TripFlowState {
        case groupSelection
        case tripTypeSelection(Group)
        case createTrip(Group, TripType)
    }
    
    enum TripTab: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
    }

    // Filtered trips based on selected type
    var filteredUpcomingTrips: [Trip] {
        guard let tripType = selectedTripType.tripType else { return upcomingTrips }
        return upcomingTrips.filter { $0.tripType == tripType }
    }

    var filteredPastTrips: [Trip] {
        guard let tripType = selectedTripType.tripType else { return pastTrips }
        return pastTrips.filter { $0.tripType == tripType }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    TripTabBar(selectedTab: $selectedTab)

                    // Trip Type Filters
                    TripTypeFilterBar(selectedFilter: $selectedTripType)

                    // Content
                    TabView(selection: $selectedTab) {
                        // Upcoming Trips
                        UpcomingTripsView(trips: filteredUpcomingTrips, selectedFilter: selectedTripType)
                            .tag(TripTab.upcoming)

                        // Past Trips
                        PastTripsView(trips: filteredPastTrips, selectedFilter: selectedTripType)
                            .tag(TripTab.past)
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
            .navigationTitle("My Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .sheet(isPresented: $showingTripFlow, onDismiss: {
                // Refresh trips when sheet is dismissed
                loadUserTrips()
            }) {
                switch tripFlowState {
                case .groupSelection:
                    GroupSelectionView { group in
                        tripFlowState = .tripTypeSelection(group)
                    }
                case .tripTypeSelection(let group):
                    TripTypeSelectionView(group: group) { tripType in
                        tripFlowState = .createTrip(group, tripType)
                    }
                case .createTrip(let group, let tripType):
                    CreateTripView(group: group, tripType: tripType)
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

                    self.upcomingTrips = trips.filter { trip in
                        trip.scheduledDate > now && trip.status == .planned
                    }

                    self.pastTrips = trips.filter { trip in
                        trip.scheduledDate <= now || trip.status == .completed
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

struct TripTypeFilterBar: View {
    @Binding var selectedFilter: MyTripsView.TripTypeFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MyTripsView.TripTypeFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}

struct FilterChip: View {
    let filter: MyTripsView.TripTypeFilter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .bulkShareTextMedium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.bulkSharePrimary : Color.bulkShareBackground)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UpcomingTripsView: View {
    let trips: [Trip]
    let selectedFilter: MyTripsView.TripTypeFilter

    var emptyState: (String, String) {
        if let tripType = selectedFilter.tripType {
            return (tripType.emptyStateMessage, tripType.emptyStateSubtitle)
        }
        return ("No Upcoming Plans", "Join or create plans to start bulk sharing")
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if trips.isEmpty {
                    EmptyTripsView(
                        icon: "calendar.badge.plus",
                        title: emptyState.0,
                        subtitle: emptyState.1
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
    let selectedFilter: MyTripsView.TripTypeFilter

    var emptyState: (String, String) {
        if let tripType = selectedFilter.tripType {
            return ("No past \(tripType.displayName.lowercased()) plans", tripType.emptyStateSubtitle)
        }
        return ("No Past Plans", "Your completed plans will appear here")
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if trips.isEmpty {
                    EmptyTripsView(
                        icon: "clock",
                        title: emptyState.0,
                        subtitle: emptyState.1
                    )
                } else {
                    ForEach(trips) { trip in
                        NavigationLink(destination: PastTripDetailView(trip: trip)) {
                            PastTripCard(trip: trip)
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

struct UpcomingTripCard: View {
    let trip: Trip

    private var isCreator: Bool {
        guard let currentUserId = FirebaseManager.shared.currentUser?.id else { return false }
        return trip.creatorId == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Trip Type
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Trip Type Badge + Creator Indicator
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(trip.tripType.icon)
                                .font(.caption)
                            Text(trip.tripType.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(trip.tripType.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(trip.tripType.accentColor.opacity(0.1))
                        .cornerRadius(8)

                        // Subtle creator indicator
                        if isCreator {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                Text("You")
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.bulkShareWarning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.bulkShareWarning.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }

                    // Plan Name
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(trip.scheduledDate, style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(trip.tripType.accentColor)

                    Text(trip.scheduledDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }

            // Items
            Text("\(trip.items.count) items shared")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)

            // Status
            HStack {
                Label("\(trip.participantCount) joined", systemImage: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.bulkShareInfo)

                Spacer()

                Badge(text: "Upcoming", color: trip.tripType.accentColor)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(trip.tripType.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PastTripCard: View {
    let trip: Trip

    private var isCreator: Bool {
        guard let currentUserId = FirebaseManager.shared.currentUser?.id else { return false }
        return trip.creatorId == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)

                    // Subtle creator indicator
                    if isCreator {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                            Text("Created by you")
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.bulkShareWarning)
                    }
                }

                Spacer()

                Badge(text: "Completed", color: .bulkShareSuccess)
            }
            
            Text(trip.scheduledDate, style: .date)
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
            
            HStack {
                Text("\(trip.items.count) items shared")
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
                Text("Create Plan")
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
                    
                    Text("Choose which group to create a plan for")
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
                        
                        Text("Create a group first to start planning")
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
            .navigationTitle("Create Plan")
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
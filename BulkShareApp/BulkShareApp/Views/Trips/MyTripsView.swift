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
    @State private var upcomingTrips: [Trip] = Trip.sampleTrips.filter { $0.isUpcoming }
    @State private var pastTrips: [Trip] = Trip.sampleTrips.filter { !$0.isUpcoming }
    
    enum TripTab: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case hosting = "Hosting"
    }
    
    var body: some View {
        NavigationView {
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
                    HostingTripsView(trips: upcomingTrips)
                        .tag(TripTab.hosting)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.large)
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

#Preview {
    MyTripsView()
}
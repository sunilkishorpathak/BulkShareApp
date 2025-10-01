//
//  TripDetailView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  TripDetailView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @State private var selectedItems: Set<String> = []
    @State private var showingJoinAlert = false
    @State private var showingSuccessAlert = false
    @State private var isLoading = false
    
    private var totalCost: Double {
        let selectedTripItems = trip.items.filter { selectedItems.contains($0.id) }
        return selectedTripItems.reduce(0) { $0 + $1.estimatedPrice }
    }
    
    private var hasSelectedItems: Bool {
        !selectedItems.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Header
                TripDetailHeader(trip: trip)
                
                // Available Items
                AvailableItemsSection(
                    items: trip.items,
                    selectedItems: $selectedItems
                )
                
                // Participants
                ParticipantsSection(trip: trip)
                
                // Join Trip Section
                if hasSelectedItems {
                    JoinTripSection(
                        totalCost: totalCost,
                        selectedCount: selectedItems.count,
                        isLoading: isLoading,
                        onJoin: {
                            showingJoinAlert = true
                        }
                    )
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: "Check out this bulk shopping trip!") {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.bulkSharePrimary)
                }
            }
        }
        .alert("Join Trip", isPresented: $showingJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                handleJoinTrip()
            }
        } message: {
            Text("Join this trip for $\(totalCost, specifier: "%.2f") (\(selectedItems.count) items)?")
        }
        .alert("Trip Joined!", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You've successfully joined the trip. You'll be notified when it's time for pickup.")
        }
    }
    
    private func handleJoinTrip() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            showingSuccessAlert = true
            selectedItems.removeAll()
        }
    }
}

struct TripDetailHeader: View {
    let trip: Trip
    @State private var shopperName: String = "Loading..."
    @State private var isLoadingShopper = true
    
    var body: some View {
        VStack(spacing: 16) {
            // Store and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(trip.store.icon) \(trip.store.displayName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text(trip.scheduledDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.scheduledDate, style: .time)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkSharePrimary)
                    
                    Text(trip.scheduledDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }
            
            // Shopper Info
            HStack {
                Text("👤")
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shopper")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text(shopperName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                }
                
                Spacer()
                
                Button("Message") {
                    // Message shopper
                }
                .font(.subheadline)
                .foregroundColor(.bulkSharePrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bulkSharePrimary.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Trip Notes
            if let notes = trip.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextDark)
                        .padding()
                        .background(Color.bulkShareBackground)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .onAppear {
            loadShopperName()
        }
    }
    
    private func loadShopperName() {
        Task {
            do {
                let shopperUser = try await FirebaseManager.shared.getUser(uid: trip.shopperId)
                DispatchQueue.main.async {
                    self.shopperName = shopperUser.name
                    self.isLoadingShopper = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.shopperName = "Unknown User"
                    self.isLoadingShopper = false
                }
            }
        }
    }
}

struct AvailableItemsSection: View {
    let items: [TripItem]
    @Binding var selectedItems: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Items (\(items.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    SelectableItemCard(
                        item: item,
                        isSelected: selectedItems.contains(item.id)
                    ) {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
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

struct SelectableItemCard: View {
    let item: TripItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .bulkSharePrimary : .bulkShareTextLight)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text("\(item.category.icon) \(item.category.displayName)")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                        
                        if item.quantityAvailable > 1 {
                            Text("• \(item.quantityAvailable) available")
                                .font(.caption)
                                .foregroundColor(.bulkShareInfo)
                        }
                    }
                }
                
                Spacer()
                
                Text("$\(item.estimatedPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkSharePrimary)
            }
            .padding()
            .background(isSelected ? Color.bulkSharePrimary.opacity(0.1) : Color.bulkShareBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.bulkSharePrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ParticipantsSection: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Participants (\(trip.participantCount))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            if trip.participantCount == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("Be the first to join this trip!")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.bulkShareBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(User.sampleUsers.prefix(trip.participantCount), id: \.id) { user in
                        HStack {
                            Text(user.initials)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.bulkSharePrimary)
                                .cornerRadius(16)
                            
                            Text(user.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.bulkShareTextDark)
                            
                            Spacer()
                            
                            Text("Joined")
                                .font(.caption)
                                .foregroundColor(.bulkShareSuccess)
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

struct JoinTripSection: View {
    let totalCost: Double
    let selectedCount: Int
    let isLoading: Bool
    let onJoin: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Cost Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Total")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("$\(totalCost, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkSharePrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(selectedCount) items")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Payment via PayPal")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }
            .padding()
            .background(Color.bulkSharePrimary.opacity(0.1))
            .cornerRadius(12)
            
            // Join Button
            Button(action: onJoin) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Join Trip")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.bulkSharePrimary)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isLoading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationView {
        TripDetailView(trip: Trip.sampleTrips[0])
    }
}
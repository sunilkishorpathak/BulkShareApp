//
//  PastTripDetailView.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI

struct PastTripDetailView: View {
    let trip: Trip
    @State private var claims: [ItemClaim] = []
    @State private var deliveries: [ItemDelivery] = []
    @State private var isLoading = false
    @State private var showingDeliveryConfirmation = false
    @State private var selectedDelivery: ItemDelivery?
    
    private var isOrganizerView: Bool {
        return trip.shopperId == FirebaseManager.shared.currentUser?.id
    }
    
    private var currentUserId: String {
        return FirebaseManager.shared.currentUser?.id ?? ""
    }
    
    // Get accepted claims for this trip
    private var acceptedClaims: [ItemClaim] {
        claims.filter { $0.status == .accepted }
    }
    
    // Get deliveries for the current user (what they should receive)
    private var userDeliveries: [ItemDelivery] {
        deliveries.filter { $0.receiverUserId == currentUserId }
    }
    
    // Get deliveries the current user should make (if they're organizer or helping deliver)
    private var deliveriesToMake: [ItemDelivery] {
        deliveries.filter { $0.delivererUserId == currentUserId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Header (similar to TripDetailView but read-only)
                PastTripHeader(trip: trip)
                
                // Show Original Trip Items (what was planned)
                TripItemsListSection(
                    title: "Trip Items (\(trip.items.count))",
                    items: trip.items,
                    claims: acceptedClaims,
                    deliveries: deliveries,
                    isOrganizerView: isOrganizerView,
                    currentUserId: currentUserId,
                    onToggleDelivery: { claim, delivery in
                        handleDeliveryToggle(claim: claim, delivery: delivery)
                    }
                )
                
                // All delivery tracking is now integrated into the main trip items list above
                
                
                // Trip Summary
                TripSummarySection(trip: trip, claims: acceptedClaims)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadTripData()
        }
        .alert("Confirm Delivery Status", isPresented: $showingDeliveryConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                if let delivery = selectedDelivery {
                    toggleDeliveryStatus(delivery)
                }
            }
        } message: {
            if let delivery = selectedDelivery {
                let action = delivery.isDelivered ? "mark as pending" : "mark as delivered"
                Text("Do you want to \(action) for this item?")
            }
        }
    }
    
    private func loadTripData() {
        isLoading = true
        
        Task {
            do {
                // Load claims for this trip
                let tripClaims = try await FirebaseManager.shared.getTripClaims(tripId: trip.id)
                let tripDeliveries = try await FirebaseManager.shared.getTripDeliveries(tripId: trip.id)
                
                DispatchQueue.main.async {
                    self.claims = tripClaims
                    self.deliveries = tripDeliveries
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error loading trip data: \(error)")
                }
            }
        }
    }
    
    private func handleDeliveryToggle(claim: ItemClaim, delivery: ItemDelivery?) {
        // If no delivery record exists, create one first
        if delivery == nil {
            createDeliveryRecord(for: claim)
        } else if let existingDelivery = delivery {
            selectedDelivery = existingDelivery
            showingDeliveryConfirmation = true
        }
    }
    
    private func createDeliveryRecord(for claim: ItemClaim) {
        Task {
            do {
                let newDelivery = ItemDelivery.createFromClaim(claim, delivererUserId: trip.shopperId)
                try await FirebaseManager.shared.createDeliveryRecord(newDelivery)
                
                DispatchQueue.main.async {
                    self.loadTripData() // Refresh to show new delivery record
                }
            } catch {
                print("Error creating delivery record: \(error)")
            }
        }
    }
    
    private func toggleDeliveryStatus(_ delivery: ItemDelivery) {
        isLoading = true
        
        Task {
            do {
                if delivery.isDelivered {
                    // Mark as not delivered (reset)
                    try await FirebaseManager.shared.markItemAsNotDelivered(deliveryId: delivery.id)
                } else {
                    // Mark as delivered
                    try await FirebaseManager.shared.markItemAsDelivered(
                        deliveryId: delivery.id,
                        deliveredAt: Date(),
                        confirmationNote: "Confirmed by \(FirebaseManager.shared.currentUser?.name ?? "user")"
                    )
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadTripData() // Refresh data
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error updating delivery status: \(error)")
                }
            }
        }
    }
}

struct PastTripHeader: View {
    let trip: Trip
    @State private var shopperName: String = "Loading..."
    
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
                    
                    Text(trip.scheduledDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                
                Spacer()
                
                Text("Completed")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.bulkShareSuccess)
                    .cornerRadius(6)
            }
            
            // Shopper Info
            HStack {
                Text("👤")
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.bulkShareSuccess.opacity(0.1))
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
                
                Text("Trip completed")
                    .font(.caption)
                    .foregroundColor(.bulkShareSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.bulkShareSuccess.opacity(0.1))
                    .cornerRadius(6)
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
                }
            } catch {
                DispatchQueue.main.async {
                    self.shopperName = "Unknown User"
                }
            }
        }
    }
}

struct TripItemsListSection: View {
    let title: String
    let items: [TripItem]
    let claims: [ItemClaim]
    let deliveries: [ItemDelivery]
    let isOrganizerView: Bool
    let currentUserId: String
    let onToggleDelivery: (ItemClaim, ItemDelivery?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No items in this trip")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.bulkShareBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        let itemClaims = claims.filter { $0.itemId == item.id }
                        let totalClaimed = itemClaims.reduce(0) { $0 + $1.quantityClaimed }
                        
                        TripItemRow(
                            item: item,
                            totalClaimed: totalClaimed,
                            availableQuantity: item.quantityAvailable,
                            claims: itemClaims,
                            deliveries: deliveries,
                            isOrganizerView: isOrganizerView,
                            currentUserId: currentUserId,
                            onToggleDelivery: onToggleDelivery
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

struct TripItemRow: View {
    let item: TripItem
    let totalClaimed: Int
    let availableQuantity: Int
    let claims: [ItemClaim]
    let deliveries: [ItemDelivery]
    let isOrganizerView: Bool
    let currentUserId: String
    let onToggleDelivery: (ItemClaim, ItemDelivery?) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("\(item.category.icon) \(item.category.displayName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextLight)
                            .italic()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available: \(availableQuantity)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Claimed: \(totalClaimed)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(totalClaimed > 0 ? .bulkShareSuccess : .bulkShareTextLight)
                    
                    Text("$\(item.estimatedPrice, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.bulkSharePrimary)
                }
            }
            
            // Show who claimed this item with delivery checkboxes
            if !claims.isEmpty {
                VStack(spacing: 4) {
                    ForEach(claims) { claim in
                        ClaimWithDeliveryRow(
                            claim: claim,
                            delivery: deliveries.first { $0.claimId == claim.id },
                            isOrganizerView: isOrganizerView,
                            currentUserId: currentUserId,
                            onToggleDelivery: onToggleDelivery
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(totalClaimed > 0 ? Color.bulkSharePrimary.opacity(0.05) : Color.bulkShareBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(totalClaimed > 0 ? Color.bulkSharePrimary.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ClaimWithDeliveryRow: View {
    let claim: ItemClaim
    let delivery: ItemDelivery?
    let isOrganizerView: Bool
    let currentUserId: String
    let onToggleDelivery: (ItemClaim, ItemDelivery?) -> Void
    @State private var claimerName: String = "Loading..."
    
    private var isDelivered: Bool {
        delivery?.isDelivered ?? false
    }
    
    private var shouldShowForUser: Bool {
        if isOrganizerView {
            return true // Organizers see all claims
        } else {
            // Participants only see their own claims
            return claim.claimerUserId == currentUserId
        }
    }
    
    var body: some View {
        if shouldShowForUser {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundColor(.bulkSharePrimary)
                
                if isOrganizerView {
                    Text("\(claimerName) claimed \(claim.quantityClaimed)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                } else {
                    Text("You claimed \(claim.quantityClaimed)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                // Delivery checkbox
                Button(action: {
                    onToggleDelivery(claim, delivery)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isDelivered ? "checkmark.square.fill" : "square")
                            .font(.subheadline)
                            .foregroundColor(isDelivered ? .green : .gray)
                        
                        Text(isOrganizerView ? "Delivered" : "Received")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isDelivered ? .green : .bulkShareTextMedium)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isDelivered ? Color.green.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .onAppear {
                if isOrganizerView {
                    loadClaimerName()
                }
            }
        }
    }
    
    private func loadClaimerName() {
        Task {
            do {
                let user = try await FirebaseManager.shared.getUser(uid: claim.claimerUserId)
                DispatchQueue.main.async {
                    self.claimerName = user.name
                }
            } catch {
                DispatchQueue.main.async {
                    self.claimerName = "Unknown User"
                }
            }
        }
    }
}






struct TripSummarySection: View {
    let trip: Trip
    let claims: [ItemClaim]
    
    private var totalItemsClaimed: Int {
        claims.reduce(0) { $0 + $1.quantityClaimed }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total items shared:")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Spacer()
                    
                    Text("\(totalItemsClaimed)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                }
                
                HStack {
                    Text("Participants:")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Spacer()
                    
                    Text("\(claims.map { $0.claimerUserId }.uniqued().count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                }
                
                HStack {
                    Text("Trip date:")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Spacer()
                    
                    Text(trip.scheduledDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// Helper extension for unique array elements
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    NavigationView {
        PastTripDetailView(trip: Trip.sampleTrips[0])
    }
}
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
                
                if isOrganizerView {
                    // Organizer View: Show all claimed items with delivery checkboxes
                    OrganizerItemsSection(
                        trip: trip,
                        claims: acceptedClaims,
                        deliveries: deliveries,
                        onToggleDelivery: { claim, delivery in
                            handleDeliveryToggle(claim: claim, delivery: delivery)
                        }
                    )
                } else {
                    // Participant View: Show their claimed items with received checkboxes
                    ParticipantItemsSection(
                        trip: trip,
                        userClaims: acceptedClaims.filter { $0.claimerUserId == currentUserId },
                        deliveries: deliveries,
                        onToggleReceived: { claim, delivery in
                            handleDeliveryToggle(claim: claim, delivery: delivery)
                        }
                    )
                }
                
                
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

struct OrganizerItemsSection: View {
    let trip: Trip
    let claims: [ItemClaim]
    let deliveries: [ItemDelivery]
    let onToggleDelivery: (ItemClaim, ItemDelivery?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Claimed Items (\(claims.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            if claims.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No items were claimed")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                        
                    Text("This trip had no participants")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.bulkShareBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(claims) { claim in
                        if let item = trip.items.first(where: { $0.id == claim.itemId }) {
                            let delivery = deliveries.first { $0.claimId == claim.id }
                            ClaimedItemCard(
                                item: item,
                                claim: claim,
                                delivery: delivery,
                                isOrganizerView: true,
                                onToggleDelivery: { onToggleDelivery(claim, delivery) }
                            )
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

struct ClaimedItemCard: View {
    let item: TripItem
    let claim: ItemClaim
    let delivery: ItemDelivery?
    let isOrganizerView: Bool
    let onToggleDelivery: () -> Void
    @State private var claimerName: String = "Loading..."
    
    private var isDelivered: Bool {
        delivery?.isDelivered ?? false
    }
    
    private var checkboxText: String {
        isOrganizerView ? "Delivered" : "Received"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    if isOrganizerView {
                        Text("Claimed by: \(claimerName)")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                    } else {
                        Text("\(item.category.icon) \(item.category.displayName)")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                    }
                    
                    Text("Quantity: \(claim.quantityClaimed)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkSharePrimary)
                }
                
                Spacer()
                
                // Checkbox for delivery status
                Button(action: onToggleDelivery) {
                    HStack(spacing: 8) {
                        Image(systemName: isDelivered ? "checkmark.square.fill" : "square")
                            .font(.title2)
                            .foregroundColor(isDelivered ? .green : .gray)
                        
                        Text(checkboxText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isDelivered ? .green : .bulkShareTextMedium)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Show delivery timestamp if delivered
            if isDelivered, let deliveredAt = delivery?.deliveredAt {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("Completed \(deliveredAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(isDelivered ? Color.green.opacity(0.05) : Color.bulkShareBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDelivered ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            if isOrganizerView {
                loadClaimerName()
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

struct ParticipantItemsSection: View {
    let trip: Trip
    let userClaims: [ItemClaim]
    let deliveries: [ItemDelivery]
    let onToggleReceived: (ItemClaim, ItemDelivery?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Items (\(userClaims.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            if userClaims.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No items claimed")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("You didn't claim any items from this trip")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.bulkShareBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(userClaims) { claim in
                        if let item = trip.items.first(where: { $0.id == claim.itemId }) {
                            let delivery = deliveries.first { $0.claimId == claim.id }
                            ClaimedItemCard(
                                item: item,
                                claim: claim,
                                delivery: delivery,
                                isOrganizerView: false,
                                onToggleDelivery: { onToggleReceived(claim, delivery) }
                            )
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
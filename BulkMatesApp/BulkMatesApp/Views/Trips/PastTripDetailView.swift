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
                    // Organizer View: Show all items and delivery status
                    AllItemsDeliverySection(
                        trip: trip,
                        claims: acceptedClaims,
                        deliveries: deliveries,
                        onMarkDelivered: { delivery in
                            selectedDelivery = delivery
                            showingDeliveryConfirmation = true
                        }
                    )
                } else {
                    // Participant View: Show their items and delivery status
                    MyItemsSection(
                        trip: trip,
                        userDeliveries: userDeliveries,
                        onMarkReceived: { delivery in
                            selectedDelivery = delivery
                            showingDeliveryConfirmation = true
                        }
                    )
                }
                
                // Show items to deliver if user is helping with delivery
                if !deliveriesToMake.isEmpty && !isOrganizerView {
                    ItemsToDeliverSection(
                        deliveries: deliveriesToMake,
                        trip: trip,
                        onMarkDelivered: { delivery in
                            selectedDelivery = delivery
                            showingDeliveryConfirmation = true
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
        .alert("Confirm Delivery", isPresented: $showingDeliveryConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark as Delivered") {
                if let delivery = selectedDelivery {
                    markAsDelivered(delivery)
                }
            }
        } message: {
            if let delivery = selectedDelivery {
                Text("Confirm that this item has been delivered to the recipient?")
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
    
    private func markAsDelivered(_ delivery: ItemDelivery) {
        isLoading = true
        
        Task {
            do {
                try await FirebaseManager.shared.markItemAsDelivered(
                    deliveryId: delivery.id,
                    deliveredAt: Date(),
                    confirmationNote: "Confirmed by \(FirebaseManager.shared.currentUser?.name ?? "user")"
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadTripData() // Refresh data
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error marking item as delivered: \(error)")
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

struct AllItemsDeliverySection: View {
    let trip: Trip
    let claims: [ItemClaim]
    let deliveries: [ItemDelivery]
    let onMarkDelivered: (ItemDelivery) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Item Deliveries (\(claims.count) items)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            if claims.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No items were claimed")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
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
                            OrganizerItemDeliveryCard(
                                item: item,
                                claim: claim,
                                delivery: delivery,
                                onMarkDelivered: onMarkDelivered
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

struct OrganizerItemDeliveryCard: View {
    let item: TripItem
    let claim: ItemClaim
    let delivery: ItemDelivery?
    let onMarkDelivered: (ItemDelivery) -> Void
    @State private var claimerName: String = "Loading..."
    
    private var isDelivered: Bool {
        delivery?.isDelivered ?? false
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("Claimed by: \(claimerName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Quantity: \(claim.quantityClaimed)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkSharePrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: isDelivered ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(isDelivered ? .green : .orange)
                        
                        Text(isDelivered ? "Delivered" : "Pending")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isDelivered ? .green : .orange)
                    }
                    
                    if let deliveredAt = delivery?.deliveredAt {
                        Text(deliveredAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextLight)
                    }
                }
            }
            
            // Mark as delivered button (only if not delivered and there's a delivery record)
            if !isDelivered, let deliveryRecord = delivery {
                Button(action: {
                    onMarkDelivered(deliveryRecord)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Delivered")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.bulkSharePrimary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(isDelivered ? Color.green.opacity(0.05) : Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDelivered ? Color.green : Color.orange, lineWidth: 1)
        )
        .onAppear {
            loadClaimerName()
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

struct MyItemsSection: View {
    let trip: Trip
    let userDeliveries: [ItemDelivery]
    let onMarkReceived: (ItemDelivery) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Items (\(userDeliveries.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            if userDeliveries.isEmpty {
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
                    ForEach(userDeliveries) { delivery in
                        if let item = trip.items.first(where: { $0.id == delivery.itemId }) {
                            UserItemDeliveryCard(
                                item: item,
                                delivery: delivery,
                                onMarkReceived: onMarkReceived
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

struct UserItemDeliveryCard: View {
    let item: TripItem
    let delivery: ItemDelivery
    let onMarkReceived: (ItemDelivery) -> Void
    @State private var delivererName: String = "Loading..."
    
    private var quantityClaimed: Int {
        // We need to get this from the claim, but for now we'll show it as 1
        // In a real implementation, we'd pass the claim or fetch it
        1
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("\(item.category.icon) \(item.category.displayName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Delivered by: \(delivererName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: delivery.isDelivered ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(delivery.isDelivered ? .green : .orange)
                        
                        Text(delivery.isDelivered ? "Received" : "Pending")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(delivery.isDelivered ? .green : .orange)
                    }
                    
                    if let deliveredAt = delivery.deliveredAt {
                        Text(deliveredAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextLight)
                    }
                }
            }
            
            // Mark as received button (only if not delivered yet)
            if !delivery.isDelivered {
                Button(action: {
                    onMarkReceived(delivery)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Received")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.bulkShareSuccess)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(delivery.isDelivered ? Color.green.opacity(0.05) : Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(delivery.isDelivered ? Color.green : Color.orange, lineWidth: 1)
        )
        .onAppear {
            loadDelivererName()
        }
    }
    
    private func loadDelivererName() {
        Task {
            do {
                let user = try await FirebaseManager.shared.getUser(uid: delivery.delivererUserId)
                DispatchQueue.main.async {
                    self.delivererName = user.name
                }
            } catch {
                DispatchQueue.main.async {
                    self.delivererName = "Unknown User"
                }
            }
        }
    }
}

struct ItemsToDeliverSection: View {
    let deliveries: [ItemDelivery]
    let trip: Trip
    let onMarkDelivered: (ItemDelivery) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Items to Deliver (\(deliveries.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                ForEach(deliveries) { delivery in
                    if let item = trip.items.first(where: { $0.id == delivery.itemId }) {
                        DeliveryTaskCard(
                            item: item,
                            delivery: delivery,
                            onMarkDelivered: onMarkDelivered
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

struct DeliveryTaskCard: View {
    let item: TripItem
    let delivery: ItemDelivery
    let onMarkDelivered: (ItemDelivery) -> Void
    @State private var receiverName: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("Deliver to: \(receiverName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: delivery.isDelivered ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(delivery.isDelivered ? .green : .orange)
                        
                        Text(delivery.isDelivered ? "Delivered" : "Pending")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(delivery.isDelivered ? .green : .orange)
                    }
                }
            }
            
            if !delivery.isDelivered {
                Button(action: {
                    onMarkDelivered(delivery)
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Delivered")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.bulkSharePrimary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(delivery.isDelivered ? Color.green.opacity(0.05) : Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(delivery.isDelivered ? Color.green : Color.blue, lineWidth: 1)
        )
        .onAppear {
            loadReceiverName()
        }
    }
    
    private func loadReceiverName() {
        Task {
            do {
                let user = try await FirebaseManager.shared.getUser(uid: delivery.receiverUserId)
                DispatchQueue.main.async {
                    self.receiverName = user.name
                }
            } catch {
                DispatchQueue.main.async {
                    self.receiverName = "Unknown User"
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
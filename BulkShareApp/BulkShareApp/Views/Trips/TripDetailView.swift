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
    @State private var selectedItems: [String: Int] = [:] // itemId: quantity
    @State private var showingJoinAlert = false
    @State private var showingSuccessAlert = false
    @State private var isLoading = false
    @State private var claims: [ItemClaim] = []
    @State private var transactions: [Transaction] = []
    
    private var totalCost: Double {
        return selectedItems.reduce(0) { total, selection in
            if let item = trip.items.first(where: { $0.id == selection.key }) {
                return total + (item.estimatedPrice * Double(selection.value))
            }
            return total
        }
    }
    
    private var hasSelectedItems: Bool {
        !selectedItems.isEmpty
    }
    
    private var totalSelectedItems: Int {
        selectedItems.values.reduce(0, +)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Header
                TripDetailHeader(trip: trip)
                
                // Available Items
                AvailableItemsSection(
                    items: trip.items,
                    selectedItems: $selectedItems,
                    claims: claims
                )
                
                // Participants
                ParticipantsSection(trip: trip)
                
                // Join Trip Section
                if hasSelectedItems {
                    JoinTripSection(
                        totalCost: totalCost,
                        selectedCount: totalSelectedItems,
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
            Text("Join this trip for $\(totalCost, specifier: "%.2f") (\(totalSelectedItems) items)?")
        }
        .alert("Trip Joined!", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You've successfully joined the trip. You'll be notified when it's time for pickup.")
        }
        .onAppear {
            loadTripData()
        }
    }
    
    private func handleJoinTrip() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                // Create claims for selected items
                var newClaims: [ItemClaim] = []
                for (itemId, quantity) in selectedItems {
                    let claim = ItemClaim(
                        tripId: trip.id,
                        itemId: itemId,
                        claimerUserId: currentUser.id,
                        quantityClaimed: quantity
                    )
                    newClaims.append(claim)
                }
                
                // Save claims to Firebase
                try await FirebaseManager.shared.createClaims(newClaims)
                
                // Create transaction for payment tracking
                let transaction = Transaction(
                    tripId: trip.id,
                    fromUserId: currentUser.id,
                    toUserId: trip.shopperId,
                    amount: totalCost,
                    itemClaimIds: newClaims.map { $0.id }
                )
                
                try await FirebaseManager.shared.createTransaction(transaction)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showingSuccessAlert = true
                    self.selectedItems.removeAll()
                    self.loadTripData() // Refresh claims
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error joining trip: \(error)")
                }
            }
        }
    }
    
    private func loadTripData() {
        Task {
            do {
                let tripClaims = try await FirebaseManager.shared.getTripClaims(tripId: trip.id)
                let tripTransactions = try await FirebaseManager.shared.getTripTransactions(tripId: trip.id)
                
                DispatchQueue.main.async {
                    self.claims = tripClaims
                    self.transactions = tripTransactions
                }
            } catch {
                print("Error loading trip data: \(error)")
            }
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
    @Binding var selectedItems: [String: Int]
    let claims: [ItemClaim]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Items (\(items.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    let remainingQty = item.remainingQuantity(claims: claims)
                    QuantitySelectableItemCard(
                        item: item,
                        remainingQuantity: remainingQty,
                        selectedQuantity: selectedItems[item.id] ?? 0,
                        onQuantityChange: { quantity in
                            if quantity > 0 {
                                selectedItems[item.id] = quantity
                            } else {
                                selectedItems.removeValue(forKey: item.id)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct QuantitySelectableItemCard: View {
    let item: TripItem
    let remainingQuantity: Int
    let selectedQuantity: Int
    let onQuantityChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
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
                        
                        Spacer()
                        
                        if remainingQuantity > 0 {
                            Text("\(remainingQuantity) remaining")
                                .font(.caption)
                                .foregroundColor(.bulkShareSuccess)
                        } else {
                            Text("Sold out")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                Text("$\(item.estimatedPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkSharePrimary)
            }
            
            // Quantity selector
            if remainingQuantity > 0 {
                HStack {
                    Text("Quantity:")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if selectedQuantity > 0 {
                                onQuantityChange(selectedQuantity - 1)
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(selectedQuantity > 0 ? .bulkSharePrimary : .gray)
                        }
                        .disabled(selectedQuantity <= 0)
                        
                        Text("\(selectedQuantity)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(minWidth: 30)
                        
                        Button(action: {
                            if selectedQuantity < remainingQuantity {
                                onQuantityChange(selectedQuantity + 1)
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(selectedQuantity < remainingQuantity ? .bulkSharePrimary : .gray)
                        }
                        .disabled(selectedQuantity >= remainingQuantity)
                    }
                }
            }
        }
        .padding()
        .background(selectedQuantity > 0 ? Color.bulkSharePrimary.opacity(0.1) : Color.bulkShareBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedQuantity > 0 ? Color.bulkSharePrimary : Color.clear, lineWidth: 1)
        )
        .opacity(remainingQuantity > 0 ? 1.0 : 0.6)
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
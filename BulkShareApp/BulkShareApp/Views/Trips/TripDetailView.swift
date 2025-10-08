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
    @State private var trip: Trip
    @State private var selectedItems: [String: Int] = [:] // itemId: quantity
    @State private var showingJoinAlert = false
    @State private var showingSuccessAlert = false
    @State private var isLoading = false
    @State private var claims: [ItemClaim] = []
    @State private var transactions: [Transaction] = []
    @State private var itemRequests: [ItemRequest] = []
    @State private var showingAddItemRequest = false
    
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
    
    private var isOrganizerView: Bool {
        return trip.shopperId == FirebaseManager.shared.currentUser?.id
    }
    
    private var pendingClaims: [ItemClaim] {
        claims.filter { $0.status == .pending }
    }
    
    private var pendingItemRequests: [ItemRequest] {
        itemRequests.filter { $0.status == .pending }
    }
    
    private var userItemRequests: [ItemRequest] {
        itemRequests.filter { $0.requesterUserId == FirebaseManager.shared.currentUser?.id }
    }
    
    init(trip: Trip) {
        self._trip = State(initialValue: trip)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Header
                TripDetailHeader(trip: trip)
                
                if isOrganizerView {
                    // Trip Organizer View
                    TripItemsOrganizerSection(
                        items: trip.items,
                        claims: claims
                    )
                    
                    // Pending Claim Requests Section
                    if !pendingClaims.isEmpty {
                        PendingRequestsSection(
                            pendingClaims: pendingClaims,
                            tripItems: trip.items,
                            onApprove: { claim in
                                handleClaimResponse(claim, .accepted)
                            },
                            onReject: { claim in
                                handleClaimResponse(claim, .rejected)
                            }
                        )
                    }
                    
                    // Pending Item Requests Section
                    if !pendingItemRequests.isEmpty {
                        PendingItemRequestsSection(
                            pendingRequests: pendingItemRequests,
                            onApprove: { request in
                                handleItemRequestResponse(request, .approved)
                            },
                            onReject: { request in
                                handleItemRequestResponse(request, .rejected)
                            }
                        )
                    }
                } else {
                    // Regular Participant View
                    AvailableItemsSection(
                        items: trip.items,
                        selectedItems: $selectedItems,
                        claims: claims
                    )
                    
                    // Request Items Section  
                    RequestItemsSection(
                        userRequests: userItemRequests,
                        onAddRequest: {
                            showingAddItemRequest = true
                        }
                    )
                    
                    // Confirm Selection Section
                    if hasSelectedItems {
                        ConfirmSelectionSection(
                            selectedCount: totalSelectedItems,
                            isLoading: isLoading,
                            onConfirm: {
                                showingJoinAlert = true
                            }
                        )
                    }
                }
                
                // Participants (shown for both views)
                ParticipantsSection(trip: trip)
                
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
        .alert("Confirm Selection", isPresented: $showingJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                handleJoinTrip()
            }
        } message: {
            Text("Confirm your selection of \(totalSelectedItems) items?")
        }
        .alert("Selection Confirmed!", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You've successfully confirmed your selection. You'll be notified when it's time for pickup.")
        }
        .onAppear {
            loadTripData()
            refreshTripData()
        }
        .sheet(isPresented: $showingAddItemRequest) {
            AddItemRequestView(tripId: trip.id) { request in
                handleItemRequestSubmission(request)
            }
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
                
                // Send notification to trip organizer
                let totalItemsRequested = newClaims.reduce(0) { $0 + $1.quantityClaimed }
                try await NotificationManager.shared.createClaimNotification(
                    tripId: trip.id,
                    tripOrganizerId: trip.shopperId,
                    claimerUserId: currentUser.id,
                    claimerName: currentUser.name,
                    itemsCount: totalItemsRequested,
                    tripStore: trip.store.displayName
                )
                
                // Create transaction for item tracking  
                let transaction = Transaction(
                    tripId: trip.id,
                    fromUserId: currentUser.id,
                    toUserId: trip.shopperId,
                    itemPoints: totalItemsRequested,
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
    
    private func handleClaimResponse(_ claim: ItemClaim, _ status: ClaimStatus) {
        isLoading = true
        
        Task {
            do {
                try await FirebaseManager.shared.updateClaimStatus(claimId: claim.id, status: status)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadTripData() // Refresh claims
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error updating claim status: \(error)")
                }
            }
        }
    }
    
    private func handleItemRequestSubmission(_ request: ItemRequest) {
        Task {
            do {
                try await FirebaseManager.shared.createItemRequest(request)
                
                // Send notification to trip organizer
                if let currentUser = FirebaseManager.shared.currentUser {
                    try await NotificationManager.shared.createItemRequestNotification(
                        tripId: trip.id,
                        tripOrganizerId: trip.shopperId,
                        requesterUserId: currentUser.id,
                        requesterName: currentUser.name,
                        itemName: request.itemName,
                        quantity: request.quantityRequested
                    )
                }
                
                DispatchQueue.main.async {
                    self.loadTripData() // Refresh requests
                }
                
            } catch {
                print("Error creating item request: \(error)")
            }
        }
    }
    
    private func handleItemRequestResponse(_ request: ItemRequest, _ status: ItemRequestStatus) {
        isLoading = true
        
        Task {
            do {
                if status == .approved {
                    // Approve request and add item to trip
                    try await FirebaseManager.shared.approveItemRequestAndAddToTrip(
                        requestId: request.id,
                        tripId: trip.id
                    )
                    
                    // Send notification to requester
                    if let currentUser = FirebaseManager.shared.currentUser {
                        try await NotificationManager.shared.createItemApprovalNotification(
                            tripId: trip.id,
                            requesterUserId: request.requesterUserId,
                            organizerUserId: currentUser.id,
                            organizerName: currentUser.name,
                            itemName: request.itemName,
                            quantity: request.quantityRequested
                        )
                    }
                } else {
                    // Just update status to rejected
                    try await FirebaseManager.shared.updateItemRequestStatus(
                        requestId: request.id,
                        status: status
                    )
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadTripData() // Refresh requests and trip items
                    self.refreshTripData() // Refresh the actual trip object
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error updating item request: \(error)")
                }
            }
        }
    }
    
    private func loadTripData() {
        Task {
            do {
                let tripClaims = try await FirebaseManager.shared.getTripClaims(tripId: trip.id)
                let tripTransactions = try await FirebaseManager.shared.getTripTransactions(tripId: trip.id)
                let tripItemRequests = try await FirebaseManager.shared.getTripItemRequests(tripId: trip.id)
                
                DispatchQueue.main.async {
                    self.claims = tripClaims
                    self.transactions = tripTransactions
                    self.itemRequests = tripItemRequests
                }
            } catch {
                print("Error loading trip data: \(error)")
            }
        }
    }
    
    private func refreshTripData() {
        Task {
            do {
                let refreshedTrip = try await FirebaseManager.shared.getTrip(tripId: trip.id)
                DispatchQueue.main.async {
                    self.trip = refreshedTrip
                }
            } catch {
                print("Error refreshing trip data: \(error)")
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
                    let userClaim = claims.first { $0.itemId == item.id && $0.claimerUserId == FirebaseManager.shared.currentUser?.id }
                    QuantitySelectableItemCard(
                        item: item,
                        remainingQuantity: remainingQty,
                        selectedQuantity: selectedItems[item.id] ?? 0,
                        userClaim: userClaim,
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
    let userClaim: ItemClaim?
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
                    
                    // Show user's claim status if exists
                    if let claim = userClaim {
                        HStack {
                            Text("Your request:")
                                .font(.caption)
                                .foregroundColor(.bulkShareTextMedium)
                            
                            Text("\(claim.quantityClaimed) items - \(claim.status.displayName)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(claim.status.color))
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
            
            // Quantity selector
            if remainingQuantity > 0 && userClaim == nil {
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
            } else if let claim = userClaim {
                HStack {
                    if claim.status == .pending {
                        Text("Request submitted")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                        
                        Spacer()
                        
                        Text("Cannot modify while pending")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if claim.status == .accepted {
                        Text("Request accepted")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("\(claim.quantityClaimed) items confirmed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    } else if claim.status == .rejected {
                        Text("Request rejected")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("Contact organizer")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(
            selectedQuantity > 0 ? Color.bulkSharePrimary.opacity(0.1) :
            userClaim?.status == .accepted ? Color.green.opacity(0.1) :
            userClaim?.status == .rejected ? Color.red.opacity(0.1) :
            Color.bulkShareBackground
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedQuantity > 0 ? Color.bulkSharePrimary :
                    userClaim?.status == .accepted ? Color.green :
                    userClaim?.status == .rejected ? Color.red :
                    userClaim?.status == .pending ? Color.orange :
                    Color.clear,
                    lineWidth: userClaim != nil ? 2 : (selectedQuantity > 0 ? 1 : 0)
                )
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

struct ConfirmSelectionSection: View {
    let selectedCount: Int
    let isLoading: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Selection Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Selection")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("\(selectedCount) items selected")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkSharePrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ready to confirm")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Review your selection")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
            }
            .padding()
            .background(Color.bulkSharePrimary.opacity(0.1))
            .cornerRadius(12)
            
            // Confirm Button
            Button(action: onConfirm) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm Selection")
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

// MARK: - Trip Organizer Components

struct TripItemsOrganizerSection: View {
    let items: [TripItem]
    let claims: [ItemClaim]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Trip Items (\(items.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    let itemClaims = claims.filter { $0.itemId == item.id }
                    OrganizerItemCard(item: item, claims: itemClaims)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct OrganizerItemCard: View {
    let item: TripItem
    let claims: [ItemClaim]
    
    private var acceptedQuantity: Int {
        claims.filter { $0.status == .accepted }.reduce(0) { $0 + $1.quantityClaimed }
    }
    
    private var pendingQuantity: Int {
        claims.filter { $0.status == .pending }.reduce(0) { $0 + $1.quantityClaimed }
    }
    
    private var remainingQuantity: Int {
        item.quantityAvailable - acceptedQuantity
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
                }
                
                Spacer()
            }
            
            // Status Summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Available: \(item.quantityAvailable)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Accepted: \(acceptedQuantity)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Pending: \(pendingQuantity)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Remaining: \(remainingQuantity)")
                        .font(.caption)
                        .foregroundColor(.bulkShareSuccess)
                }
            }
        }
        .padding()
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

struct PendingRequestsSection: View {
    let pendingClaims: [ItemClaim]
    let tripItems: [TripItem]
    let onApprove: (ItemClaim) -> Void
    let onReject: (ItemClaim) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Requests (\(pendingClaims.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                ForEach(pendingClaims) { claim in
                    if let item = tripItems.first(where: { $0.id == claim.itemId }) {
                        PendingClaimCard(
                            claim: claim,
                            item: item,
                            onApprove: { onApprove(claim) },
                            onReject: { onReject(claim) }
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

struct PendingClaimCard: View {
    let claim: ItemClaim
    let item: TripItem
    let onApprove: () -> Void
    let onReject: () -> Void
    @State private var requesterName: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("Requested by: \(requesterName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Quantity: \(claim.quantityClaimed)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkSharePrimary)
                }
                
                Spacer()
                
                Text(claim.claimedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
            
            // Approve/Reject Buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: onApprove) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Approve")
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
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
        .onAppear {
            loadRequesterName()
        }
    }
    
    private func loadRequesterName() {
        Task {
            do {
                let user = try await FirebaseManager.shared.getUser(uid: claim.claimerUserId)
                DispatchQueue.main.async {
                    self.requesterName = user.name
                }
            } catch {
                DispatchQueue.main.async {
                    self.requesterName = "Unknown User"
                }
            }
        }
    }
}

// MARK: - Item Request Components

struct RequestItemsSection: View {
    let userRequests: [ItemRequest]
    let onAddRequest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Request Additional Items")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                Button(action: onAddRequest) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Request Item")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            
            if userRequests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No item requests yet")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Request additional items you need from this trip")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.bulkShareBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(userRequests) { request in
                        UserItemRequestCard(request: request)
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

struct UserItemRequestCard: View {
    let request: ItemRequest
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.itemName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("\(request.category.icon) \(request.category.displayName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Qty: \(request.quantityRequested)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text(request.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(request.status.color))
                }
            }
            
            if let notes = request.notes, !notes.isEmpty {
                HStack {
                    Text("Note: \(notes)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    Spacer()
                }
            }
            
            // Show additional info for approved requests
            if request.status == .approved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Item added to trip and available for selection")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(request.status == .approved ? Color.green.opacity(0.05) : Color.bulkShareBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(request.status.color), lineWidth: request.status == .approved ? 2 : 1)
        )
    }
}

struct PendingItemRequestsSection: View {
    let pendingRequests: [ItemRequest]
    let onApprove: (ItemRequest) -> Void
    let onReject: (ItemRequest) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Item Requests (\(pendingRequests.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            VStack(spacing: 12) {
                ForEach(pendingRequests) { request in
                    PendingItemRequestCard(
                        request: request,
                        onApprove: { onApprove(request) },
                        onReject: { onReject(request) }
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

struct PendingItemRequestCard: View {
    let request: ItemRequest
    let onApprove: () -> Void
    let onReject: () -> Void
    @State private var requesterName: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.itemName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("Requested by: \(requesterName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("\(request.category.icon) \(request.category.displayName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("Quantity: \(request.quantityRequested)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkSharePrimary)
                }
                
                Spacer()
                
                Text(request.requestedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
            
            if let notes = request.notes, !notes.isEmpty {
                HStack {
                    Text("Note: \(notes)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.bulkShareBackground)
                        .cornerRadius(6)
                    Spacer()
                }
            }
            
            // Approve/Reject Buttons
            HStack(spacing: 12) {
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: onApprove) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Approve & Add")
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
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 1)
        )
        .onAppear {
            loadRequesterName()
        }
    }
    
    private func loadRequesterName() {
        Task {
            do {
                let user = try await FirebaseManager.shared.getUser(uid: request.requesterUserId)
                DispatchQueue.main.async {
                    self.requesterName = user.name
                }
            } catch {
                DispatchQueue.main.async {
                    self.requesterName = "Unknown User"
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TripDetailView(trip: Trip.sampleTrips[0])
    }
}
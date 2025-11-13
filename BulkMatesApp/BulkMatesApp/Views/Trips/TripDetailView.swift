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
    @State private var showingClaimItem = false
    @State private var selectedItemToClaim: TripItem?
    @State private var itemFilter: ItemFilter = .all
    @State private var itemSort: ItemSort = .name
    @State private var itemComments: [ItemComment] = []
    @State private var showingMembersView = false
    @State private var showingActivityFeed = false
    @State private var showingPlanMenu = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditPlan = false
    @State private var groupInfo: Group?
    @Environment(\.dismiss) private var dismiss

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

    private var currentUserId: String {
        return FirebaseManager.shared.currentUser?.id ?? ""
    }

    private var currentUserRole: TripRole {
        return trip.userRole(userId: currentUserId)
    }

    private var canEditList: Bool {
        return trip.canEditList(userId: currentUserId)
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
    
    enum ItemFilter: String, CaseIterable {
        case all = "All Items"
        case unclaimed = "Unclaimed"
        case myClaims = "My Claims"
        case partiallyFilled = "Partially Filled"
    }

    enum ItemSort: String, CaseIterable {
        case name = "Name"
        case quantity = "Quantity"
        case status = "Status"
    }

    init(trip: Trip) {
        self._trip = State(initialValue: trip)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Header
                TripDetailHeader(trip: trip, claims: claims, groupInfo: groupInfo)
                
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
                        claims: claims,
                        itemComments: itemComments,
                        filter: $itemFilter,
                        sort: $itemSort,
                        onItemTap: { item in
                            selectedItemToClaim = item
                            showingClaimItem = true
                        }
                    )
                    
                    // Request Items Section
                    RequestItemsSection(
                        userRequests: userItemRequests,
                        onAddRequest: {
                            showingAddItemRequest = true
                        }
                    )
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
            ToolbarItem(placement: .navigationBarLeading) {
                if canEditList {
                    Button(action: {
                        showingMembersView = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                            Text("\(trip.totalMemberCount)")
                        }
                        .foregroundColor(.bulkSharePrimary)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Activity feed button
                    Button(action: {
                        showingActivityFeed = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            if trip.activityCount > 0 {
                                Text("\(trip.activityCount)")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.bulkSharePrimary)
                    }

                    // Menu button (only for creator/admin)
                    if canEditList {
                        Button(action: {
                            showingPlanMenu = true
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.bulkSharePrimary)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Plan Options", isPresented: $showingPlanMenu, titleVisibility: .visible) {
            Button("Edit Plan Details") {
                showingEditPlan = true
            }
            Button("Delete Plan", role: .destructive) {
                showingDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Plan?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePlan()
            }
        } message: {
            Text("Are you sure you want to delete this plan? This cannot be undone.")
        }
        .sheet(isPresented: $showingMembersView) {
            TripMembersView(trip: trip)
        }
        .sheet(isPresented: $showingActivityFeed) {
            NavigationView {
                PlanActivityFeedView(trip: trip)
                    .environmentObject(FirebaseManager.shared)
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
            Task {
                await loadTripData()
                await loadGroupInfo()
                refreshTripData()
            }
        }
        .sheet(isPresented: $showingEditPlan) {
            if let group = groupInfo {
                NavigationView {
                    EditPlanDetailsView(trip: $trip, group: group)
                }
            }
        }
        .sheet(isPresented: $showingAddItemRequest) {
            AddItemRequestView(tripId: trip.id) { request in
                handleItemRequestSubmission(request)
            }
        }
        .sheet(isPresented: $showingClaimItem) {
            if let item = selectedItemToClaim {
                let itemClaims = claims.filter { $0.itemId == item.id }
                let itemComments = itemComments.filter { $0.itemId == item.id }
                ClaimItemView(
                    item: item,
                    existingClaims: itemClaims,
                    existingComments: itemComments,
                    tripShopperId: trip.shopperId,
                    onClaim: { quantity in
                        handleClaimItem(item: item, quantity: quantity)
                    },
                    onToggleCompletion: { claim in
                        handleToggleCompletion(claim: claim)
                    },
                    onAddComment: { text in
                        handleAddComment(item: item, text: text)
                    }
                )
            }
        }
    }
    
    private func handleToggleCompletion(claim: ItemClaim) {
        isLoading = true

        Task {
            do {
                // Toggle completion status
                let updatedCompletion = !claim.isCompleted
                let completedAt = updatedCompletion ? Date() : nil

                // TODO: Implement FirebaseManager.updateClaimCompletion method
                // See FIREBASE_BACKEND_IMPLEMENTATION.md for implementation details
                // try await FirebaseManager.shared.updateClaimCompletion(
                //     claimId: claim.id,
                //     isCompleted: updatedCompletion,
                //     completedAt: completedAt
                // )

                // For now, update claim locally (will be lost on refresh)
                if let index = claims.firstIndex(where: { $0.id == claim.id }) {
                    claims[index].isCompleted = updatedCompletion
                    claims[index].completedAt = completedAt
                }

                print("Claim completion toggled (not saved to Firebase yet)")

                // Reload claims to get updated state (when Firebase is implemented)
                // await loadTripData()

                // Check if all items are now completed
                let allClaims = claims // Use local claims for now
                let acceptedClaims = allClaims.filter { $0.status == .accepted }
                let allCompleted = !acceptedClaims.isEmpty && acceptedClaims.allSatisfy { $0.isCompleted }

                if allCompleted && updatedCompletion {
                    // TODO: Implement NotificationManager.createAllItemsCompletedNotification method
                    // See FIREBASE_BACKEND_IMPLEMENTATION.md for implementation details
                    // Send notification to trip organizer
                    // if let currentUser = FirebaseManager.shared.currentUser {
                    //     try await NotificationManager.shared.createAllItemsCompletedNotification(
                    //         tripId: trip.id,
                    //         tripOrganizerId: trip.shopperId,
                    //         completedByUserId: currentUser.id,
                    //         completedByName: currentUser.name,
                    //         tripStore: trip.store.displayName
                    //     )
                    // }
                    print("All items completed! (Notification not sent - method not implemented yet)")
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                }

            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error toggling completion: \(error)")
                }
            }
        }
    }

    private func handleAddComment(item: TripItem, text: String) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }

        Task {
            do {
                // Create comment
                let comment = ItemComment(
                    tripId: trip.id,
                    itemId: item.id,
                    userId: currentUser.id,
                    text: text
                )

                // TODO: Implement FirebaseManager.createItemComment method
                // See FIREBASE_BACKEND_IMPLEMENTATION.md for implementation details
                // try await FirebaseManager.shared.createItemComment(comment)

                // For now, add comment locally to show UI (will be lost on refresh)
                itemComments.append(comment)

                print("Comment created (not saved to Firebase yet): \(comment.text)")

                // Refresh comments when Firebase method is implemented
                // await loadTripData()

            } catch {
                print("Error adding comment: \(error)")
            }
        }
    }

    private func handleClaimItem(item: TripItem, quantity: Int) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }

        isLoading = true

        Task {
            do {
                // Create claim for the item
                let claim = ItemClaim(
                    tripId: trip.id,
                    itemId: item.id,
                    claimerUserId: currentUser.id,
                    quantityClaimed: quantity
                )

                // Save claim to Firebase
                try await FirebaseManager.shared.createClaims([claim])

                // Send notification to trip organizer
                try await NotificationManager.shared.createClaimNotification(
                    tripId: trip.id,
                    tripOrganizerId: trip.shopperId,
                    claimerUserId: currentUser.id,
                    claimerName: currentUser.name,
                    itemsCount: quantity,
                    tripStore: trip.store.displayName
                )

                // Create transaction for item tracking
                let transaction = Transaction(
                    tripId: trip.id,
                    fromUserId: currentUser.id,
                    toUserId: trip.shopperId,
                    itemPoints: quantity,
                    itemClaimIds: [claim.id]
                )

                try await FirebaseManager.shared.createTransaction(transaction)

                // Refresh claims
                await loadTripData()

                DispatchQueue.main.async {
                    self.isLoading = false
                }

            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error claiming item: \(error)")
                }
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

                // Refresh claims
                await loadTripData()

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showingSuccessAlert = true
                    self.selectedItems.removeAll()
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

                // Refresh claims
                await loadTripData()

                DispatchQueue.main.async {
                    self.isLoading = false
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

                // Refresh requests
                await loadTripData()

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

                // Refresh requests and trip items
                await loadTripData()
                refreshTripData() // Refresh the actual trip object

                DispatchQueue.main.async {
                    self.isLoading = false
                }

            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error updating item request: \(error)")
                }
            }
        }
    }
    
    private func deletePlan() {
        isLoading = true

        Task {
            do {
                try await FirebaseManager.shared.deleteTrip(tripId: trip.id)
                DispatchQueue.main.async {
                    isLoading = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    print("Error deleting plan: \(error)")
                }
            }
        }
    }

    private func loadGroupInfo() async {
        do {
            let group = try await FirebaseManager.shared.getGroup(groupId: trip.groupId)
            DispatchQueue.main.async {
                self.groupInfo = group
            }
        } catch {
            print("Error loading group info: \(error)")
        }
    }

    private func loadTripData() async {
        do {
            let tripClaims = try await FirebaseManager.shared.getTripClaims(tripId: trip.id)
            let tripTransactions = try await FirebaseManager.shared.getTripTransactions(tripId: trip.id)
            let tripItemRequests = try await FirebaseManager.shared.getTripItemRequests(tripId: trip.id)

            // TODO: Implement FirebaseManager.getTripItemComments method
            // See FIREBASE_BACKEND_IMPLEMENTATION.md for implementation details
            // let tripComments = try await FirebaseManager.shared.getTripItemComments(tripId: trip.id)
            let tripComments: [ItemComment] = [] // Empty for now until Firebase method is implemented

            DispatchQueue.main.async {
                self.claims = tripClaims
                self.transactions = tripTransactions
                self.itemRequests = tripItemRequests
                self.itemComments = tripComments
            }
        } catch {
            print("Error loading trip data: \(error)")
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
    let claims: [ItemClaim]
    let groupInfo: Group?
    @State private var shopperName: String = "Loading..."
    @State private var isLoadingShopper = true
    @State private var navigateToGroup = false

    private var completionStats: (completed: Int, total: Int) {
        let acceptedClaims = claims.filter { $0.status == .accepted }
        let completedCount = acceptedClaims.filter { $0.isCompleted }.count
        return (completedCount, acceptedClaims.count)
    }

    private var completionPercentage: Double {
        let stats = completionStats
        guard stats.total > 0 else { return 0 }
        return Double(stats.completed) / Double(stats.total)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Group Context (if available)
            if let group = groupInfo {
                NavigationLink(destination: GroupDetailView(group: group)) {
                    HStack(spacing: 6) {
                        Text(group.icon)
                            .font(.caption)
                        Text(group.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.bulkSharePrimary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.bulkShareTextLight)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Plan Name and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
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

            // Completion Progress
            if completionStats.total > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.bulkSharePrimary)
                            .font(.caption)

                        Text("Completion Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.bulkShareTextMedium)

                        Spacer()

                        Text("\(completionStats.completed) of \(completionStats.total) items completed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(completionPercentage == 1.0 ? .green : .bulkSharePrimary)
                    }

                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.bulkShareBackground)
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.bulkSharePrimary, Color.bulkShareSuccess]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(completionPercentage), height: 8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completionPercentage)
                        }
                    }
                    .frame(height: 8)

                    if completionPercentage == 1.0 {
                        HStack {
                            Image(systemName: "party.popper.fill")
                                .foregroundColor(.green)
                            Text("All items completed!")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.bulkSharePrimary.opacity(0.05))
                .cornerRadius(12)
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
    let claims: [ItemClaim]
    let itemComments: [ItemComment]
    @Binding var filter: TripDetailView.ItemFilter
    @Binding var sort: TripDetailView.ItemSort
    let onItemTap: (TripItem) -> Void

    private var filteredAndSortedItems: [TripItem] {
        let currentUserId = FirebaseManager.shared.currentUser?.id

        // Filter items
        var filtered = items
        switch filter {
        case .all:
            break
        case .unclaimed:
            filtered = items.filter { item in
                let remaining = item.remainingQuantity(claims: claims)
                return remaining > 0
            }
        case .myClaims:
            filtered = items.filter { item in
                claims.contains { $0.itemId == item.id && $0.claimerUserId == currentUserId }
            }
        case .partiallyFilled:
            filtered = items.filter { item in
                let claimed = item.claimedQuantity(claims: claims)
                let remaining = item.remainingQuantity(claims: claims)
                return claimed > 0 && remaining > 0
            }
        }

        // Sort items
        switch sort {
        case .name:
            return filtered.sorted { $0.name < $1.name }
        case .quantity:
            return filtered.sorted { item1, item2 in
                let remaining1 = item1.remainingQuantity(claims: claims)
                let remaining2 = item2.remainingQuantity(claims: claims)
                return remaining1 > remaining2
            }
        case .status:
            return filtered.sorted { item1, item2 in
                let progress1 = Double(item1.claimedQuantity(claims: claims)) / Double(item1.totalQuantity)
                let progress2 = Double(item2.claimedQuantity(claims: claims)) / Double(item2.totalQuantity)
                return progress1 < progress2
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with count
            HStack {
                Text("Available Items (\(filteredAndSortedItems.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                Spacer()
            }

            // Filter and Sort Controls
            HStack(spacing: 12) {
                // Filter Menu
                Menu {
                    ForEach(TripDetailView.ItemFilter.allCases, id: \.self) { filterOption in
                        Button(action: {
                            filter = filterOption
                        }) {
                            HStack {
                                Text(filterOption.rawValue)
                                if filter == filterOption {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filter.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkSharePrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(8)
                }

                // Sort Menu
                Menu {
                    ForEach(TripDetailView.ItemSort.allCases, id: \.self) { sortOption in
                        Button(action: {
                            sort = sortOption
                        }) {
                            HStack {
                                Text(sortOption.rawValue)
                                if sort == sortOption {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sort.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkSharePrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }

            // Items List
            if filteredAndSortedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)

                    Text("No items found")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)

                    Text("Try adjusting your filters")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.bulkShareBackground)
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredAndSortedItems) { item in
                        let itemClaims = claims.filter { $0.itemId == item.id }
                        let itemCommentCount = itemComments.filter { $0.itemId == item.id }.count
                        ItemWithClaimsCard(
                            item: item,
                            claims: itemClaims,
                            commentCount: itemCommentCount,
                            onTap: {
                                onItemTap(item)
                            }
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

struct ItemWithClaimsCard: View {
    let item: TripItem
    let claims: [ItemClaim]
    let commentCount: Int
    let onTap: () -> Void
    @State private var claimerNames: [String: String] = [:]

    private var claimedQuantity: Int {
        item.claimedQuantity(claims: claims)
    }

    private var remainingQuantity: Int {
        item.remainingQuantity(claims: claims)
    }

    private var progressPercentage: Double {
        guard item.totalQuantity > 0 else { return 0 }
        return Double(claimedQuantity) / Double(item.totalQuantity)
    }

    private var progressColor: Color {
        if progressPercentage == 0 {
            return .red
        } else if progressPercentage >= 1.0 {
            return .green
        } else {
            return .orange
        }
    }

    private var activeClaims: [ItemClaim] {
        claims.filter { $0.status != .cancelled && $0.status != .rejected }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Item Header
                HStack(alignment: .top) {
                    Text(item.category.icon)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.bulkShareTextDark)
                            .multilineTextAlignment(.leading)

                        Text(item.category.displayName)
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                    }

                    Spacer()

                    // Comment Badge
                    if commentCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption2)
                            Text("\(commentCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.bulkShareInfo)
                        .cornerRadius(12)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }

                // Progress Section
                VStack(spacing: 8) {
                    HStack {
                        Text("\(claimedQuantity) / \(item.totalQuantity) claimed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(progressColor)

                        Spacer()

                        Text("\(remainingQuantity) remaining")
                            .font(.caption)
                            .foregroundColor(remainingQuantity > 0 ? .bulkShareSuccess : .bulkShareTextMedium)
                    }

                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.bulkShareBackground)
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: geometry.size.width * CGFloat(min(progressPercentage, 1.0)), height: 8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressPercentage)
                        }
                    }
                    .frame(height: 8)
                }

                // Claims List
                if !activeClaims.isEmpty {
                    Divider()

                    VStack(spacing: 6) {
                        ForEach(activeClaims.prefix(3)) { claim in
                            HStack(spacing: 8) {
                                // Completion/Status Icon
                                if claim.isCompleted {
                                    Image(systemName: "checkmark.square.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else if claim.status == .accepted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                // Name with strikethrough if completed
                                Text(claimerNames[claim.claimerUserId] ?? "Loading...")
                                    .font(.caption)
                                    .foregroundColor(claim.isCompleted ? .bulkShareTextLight : .bulkShareTextDark)
                                    .strikethrough(claim.isCompleted, color: .bulkShareTextLight)

                                Text(":")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextLight)

                                // Quantity with strikethrough if completed
                                Text("\(claim.quantityClaimed) pcs")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(claim.isCompleted ? .bulkShareTextLight : (claim.status == .accepted ? .green : .orange))
                                    .strikethrough(claim.isCompleted, color: .bulkShareTextLight)

                                Spacer()
                            }
                        }

                        if activeClaims.count > 3 {
                            HStack {
                                Text("+\(activeClaims.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextMedium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.bulkShareBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadClaimerNames()
        }
    }

    private func loadClaimerNames() {
        Task {
            var names: [String: String] = [:]
            for claim in claims {
                do {
                    let user = try await FirebaseManager.shared.getUser(uid: claim.claimerUserId)
                    names[claim.claimerUserId] = user.name
                } catch {
                    names[claim.claimerUserId] = "Unknown"
                }
            }

            DispatchQueue.main.async {
                self.claimerNames = names
            }
        }
    }
}

struct QuantitySelectableItemCard: View {
    let item: TripItem
    let remainingQuantity: Int
    let selectedQuantity: Int
    let userClaim: ItemClaim?
    let onQuantityChange: (Int) -> Void
    @State private var showFullImage = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Item Photo Thumbnail
                if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .clipped()
                                .onTapGesture {
                                    showFullImage = true
                                }
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .sheet(isPresented: $showFullImage) {
                        FullSizeImageView(imageURL: imageURL, itemName: item.name)
                    }
                } else {
                    placeholderImage
                }

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

    // Placeholder view for items without photos
    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)

            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }

    // Loading placeholder while image is fetching
    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 80, height: 80)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
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

                    Text("Be the first to join this plan!")
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
            Text("Your Plan Items (\(items.count))")
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
    @State private var showFullImage = false

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
            HStack(spacing: 12) {
                // Item Photo Thumbnail
                if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .clipped()
                                .onTapGesture {
                                    showFullImage = true
                                }
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .sheet(isPresented: $showFullImage) {
                        FullSizeImageView(imageURL: imageURL, itemName: item.name)
                    }
                } else {
                    placeholderImage
                }

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

    // Placeholder view for items without photos
    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)

            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }

    // Loading placeholder while image is fetching
    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 80, height: 80)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
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

                    Text("Request additional items you need from this plan")
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

                    Text("Item added to plan and available for selection")
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

// MARK: - Edit Plan Details View
struct EditPlanDetailsView: View {
    @Binding var trip: Trip
    let group: Group
    @Environment(\.dismiss) private var dismiss
    @State private var planName: String = ""
    @State private var selectedTripType: TripType = .shopping
    @State private var scheduledDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Edit Plan Details")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 16) {
                    // Plan Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Enter plan name", text: $planName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Plan Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan Type")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Picker("Plan Type", selection: $selectedTripType) {
                            ForEach(TripType.allCases, id: \.self) { type in
                                HStack {
                                    Text(type.icon)
                                    Text(type.displayName)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        DatePicker("", selection: $scheduledDate, in: Date()...)
                            .datePickerStyle(CompactDatePickerStyle())
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.bulkShareTextDark)

                        ZStack(alignment: .topLeading) {
                            // Background and border
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            // Placeholder text
                            if notes.isEmpty {
                                Text("Add notes about this plan...")
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .font(.body)
                            }

                            // Text editor
                            TextEditor(text: $notes)
                                .frame(height: 120)
                                .padding(4)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.bulkShareTextDark)
                                .font(.body)
                        }
                        .frame(height: 120)
                    }

                    // Save Button
                    Button(action: savePlan) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.bulkSharePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isSaving || planName.isEmpty)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.bulkShareBackground.ignoresSafeArea())
        .navigationTitle("Edit Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.bulkSharePrimary)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            planName = trip.name
            selectedTripType = trip.tripType
            scheduledDate = trip.scheduledDate
            notes = trip.notes ?? ""
        }
    }

    private func savePlan() {
        isSaving = true

        Task {
            do {
                // Update trip locally
                trip.name = planName
                trip.tripType = selectedTripType
                trip.scheduledDate = scheduledDate
                trip.notes = notes.isEmpty ? nil : notes

                // TODO: Add updateTrip method to FirebaseManager
                // For now, just dismiss
                // try await FirebaseManager.shared.updateTrip(trip)

                DispatchQueue.main.async {
                    isSaving = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false
                    errorMessage = "Failed to save changes: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Full-Size Image View

struct FullSizeImageView: View {
    let imageURL: String
    let itemName: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            // Reset if zoomed out too far
                                            if scale < 1.0 {
                                                withAnimation {
                                                    scale = 1.0
                                                    lastScale = 1.0
                                                }
                                            }
                                            // Limit maximum zoom
                                            if scale > 5.0 {
                                                withAnimation {
                                                    scale = 5.0
                                                    lastScale = 5.0
                                                }
                                            }
                                        }
                                )
                                .onTapGesture(count: 2) {
                                    // Double tap to reset zoom
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                        case .failure(_):
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                Text("Failed to load image")
                                    .foregroundColor(.white)
                            }
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle(itemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    NavigationView {
        TripDetailView(trip: Trip.sampleTrips[0])
    }
}
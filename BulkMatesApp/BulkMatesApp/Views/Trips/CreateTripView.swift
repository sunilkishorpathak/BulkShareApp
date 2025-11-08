//
//  CreateTripView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  CreateTripView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct CreateTripView: View {
    let group: Group
    let tripType: TripType
    @State private var planName: String = ""
    @State private var selectedStore: Store = .costco
    @State private var scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var notes: String = ""
    @State private var tripItems: [TripItem] = []
    @State private var showingAddItem = false
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trip Type Badge
                        TripTypeBadge(tripType: tripType)

                        // Plan Name Field
                        PlanNameSection(planName: $planName)

                        // Trip Header
                        TripHeaderCard(group: group, tripType: tripType, store: $selectedStore, date: $scheduledDate)

                        // Items Section
                        TripItemsSection(
                            tripType: tripType,
                            items: $tripItems,
                            onAddItem: { showingAddItem = true },
                            onRemoveItem: removeItem
                        )
                        
                        // Notes Section
                        TripNotesSection(notes: $notes)
                        
                        // Create Button
                        CreateTripButton(
                            isValid: isFormValid,
                            isLoading: isLoading,
                            action: handleCreateTrip
                        )
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generateDefaultPlanName()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bulkSharePrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Home") { 
                        // Dismiss all the way to root
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddTripItemView(tripType: tripType) { item in
                    tripItems.append(item)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                if alertTitle == "Plan Created!" {
                    Button("Create Another") {
                        // Reset form for another plan
                        resetForm()
                    }
                    Button("Go Home") {
                        dismiss()
                    }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !tripItems.isEmpty &&
               scheduledDate > Date()
    }

    private func removeItem(at index: Int) {
        tripItems.remove(at: index)
    }

    private func generateDefaultPlanName() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let dateString = dateFormatter.string(from: scheduledDate)

        switch tripType {
        case .shopping:
            planName = "Shopping - \(dateString)"
        case .events:
            planName = "Event - \(dateString)"
        case .trips:
            planName = "Trip - \(dateString)"
        }
    }
    
    private func handleCreateTrip() {
        guard let currentUser = FirebaseManager.shared.currentUser else {
            showAlert(title: "Error", message: "Please sign in to create a plan")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Create the trip object
                let trip = Trip(
                    name: planName,
                    groupId: group.id,
                    shopperId: currentUser.id,
                    tripType: tripType,
                    store: selectedStore,
                    scheduledDate: scheduledDate,
                    items: tripItems,
                    status: .planned,
                    participants: [],
                    notes: notes.isEmpty ? nil : notes,
                    creatorId: currentUser.id,
                    adminIds: [currentUser.id],
                    viewerIds: []
                )

                // Save to Firestore
                let tripId = try await FirebaseManager.shared.createTrip(trip)

                DispatchQueue.main.async {
                    self.isLoading = false
                    let tripTypeText = self.tripType == .shopping ? self.selectedStore.displayName : self.tripType.displayName
                    self.showAlert(
                        title: "Plan Created!",
                        message: "Your \(tripTypeText) plan with \(self.tripItems.count) items has been posted to \(self.group.name)."
                    )
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Error",
                        message: "Failed to create plan: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func resetForm() {
        tripItems.removeAll()
        scheduledDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        notes = ""
        selectedStore = .costco
        alertTitle = ""
        alertMessage = ""
        generateDefaultPlanName()
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct TripTypeBadge: View {
    let tripType: TripType

    var body: some View {
        HStack(spacing: 8) {
            Text(tripType.icon)
                .font(.title3)
            Text(tripType.displayName)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .foregroundColor(.bulkSharePrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bulkSharePrimary.opacity(0.1))
        .cornerRadius(20)
    }
}

struct TripHeaderCard: View {
    let group: Group
    let tripType: TripType
    @Binding var store: Store
    @Binding var date: Date

    var headerText: String {
        switch tripType {
        case .shopping:
            return "Shopping for"
        case .events:
            return "Planning event for"
        case .trips:
            return "Planning trip for"
        }
    }

    var datePrompt: String {
        switch tripType {
        case .shopping:
            return "When are you going?"
        case .events:
            return "When is the event?"
        case .trips:
            return "When is it?"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Group Info
            HStack {
                Text(group.icon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(headerText)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)

                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                }

                Spacer()
            }
            
            // Store Selection (only for shopping)
            if tripType == .shopping {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Store")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextMedium)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Store.allCases, id: \.self) { storeOption in
                                StoreSelectionCard(
                                    store: storeOption,
                                    isSelected: store == storeOption
                                ) {
                                    store = storeOption
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }

            // Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text(datePrompt)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextMedium)
                
                DatePicker(
                    "",
                    selection: $date,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct StoreSelectionCard: View {
    let store: Store
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(store.icon)
                    .font(.title2)
                
                Text(store.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.bulkSharePrimary.opacity(0.1) : Color.bulkShareBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.bulkSharePrimary : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(isSelected ? .bulkSharePrimary : .bulkShareTextMedium)
    }
}

struct TripItemsSection: View {
    let tripType: TripType
    @Binding var items: [TripItem]
    let onAddItem: () -> Void
    let onRemoveItem: (Int) -> Void

    var sectionTitle: String {
        switch tripType {
        case .shopping:
            return "Items to Share"
        case .events:
            return "Event Items Needed"
        case .trips:
            return "Supplies Needed"
        }
    }

    var emptyStateMessage: String {
        switch tripType {
        case .shopping:
            return "Add items you want to share from your bulk purchase"
        case .events:
            return "Add items needed for your event or potluck"
        case .trips:
            return "Add supplies and gear needed for the trip"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Spacer()
                
                Button(action: onAddItem) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Item")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.bulkShareTextLight)
                    
                    Text("No items added yet")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)

                    Text(emptyStateMessage)
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
                    ForEach(items.indices, id: \.self) { index in
                        TripItemCard(
                            item: items[index],
                            onRemove: { onRemoveItem(index) }
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

struct TripItemCard: View {
    let item: TripItem
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Show thumbnail if image exists
            if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .clipped()
                    case .failure(_):
                        Image(systemName: "photo.fill")
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)

                HStack {
                    Text("\(item.category.icon) \(item.category.displayName)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)

                    Spacer()

                    Text("\(item.quantityAvailable) available")
                        .font(.caption)
                        .foregroundColor(.bulkShareInfo)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Button(action: onRemove) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

struct TripNotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextDark)
            
            TextField("Add any special instructions or details...", text: $notes, axis: .vertical)
                .textFieldStyle(BulkShareTextFieldStyle())
                .lineLimit(3, reservesSpace: true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct PlanNameSection: View {
    @Binding var planName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Plan Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)

                Spacer()

                if !planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.bulkShareSuccess)
                        .font(.subheadline)
                }
            }

            TextField("Enter plan name (e.g., Emma's Birthday Party)", text: $planName)
                .textFieldStyle(BulkShareTextFieldStyle())
                .font(.system(size: 16))

            if planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.bulkShareWarning)
                        .font(.caption)
                    Text("Plan name is required")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct CreateTripButton: View {
    let isValid: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "cart.fill.badge.plus")
                    Text("Create Plan")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isValid ? Color.bulkSharePrimary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(!isValid || isLoading)
        .padding(.horizontal)
    }
}

#Preview {
    CreateTripView(group: Group.sampleGroups[0], tripType: .shopping)
}

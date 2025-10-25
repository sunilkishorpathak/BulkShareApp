//
//  AddTripItemView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  AddTripItemView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct AddTripItemView: View {
    let tripType: TripType
    @State private var itemName: String = ""
    @State private var quantity: Int = 1
    @State private var selectedCategory: ItemCategory = .grocery
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss

    let onAdd: (TripItem) -> Void

    var relevantCategories: [ItemCategory] {
        ItemCategory.categoriesFor(tripType: tripType)
    }

    var headerTitle: String {
        switch tripType {
        case .bulkShopping:
            return "Add Item to Share"
        case .eventPlanning:
            return "Add Event Item"
        case .groupTrip:
            return "Add Supply"
        case .potluckMeal:
            return "Add Food/Supply"
        }
    }

    var headerSubtitle: String {
        switch tripType {
        case .bulkShopping:
            return "What item do you want to share with your group?"
        case .eventPlanning:
            return "What do you need for the event?"
        case .groupTrip:
            return "What supplies are needed?"
        case .potluckMeal:
            return "What food or supplies can people bring?"
        }
    }

    var quantityLabel: String {
        switch tripType {
        case .bulkShopping:
            return "Quantity Available (0-20)"
        case .eventPlanning, .groupTrip, .potluckMeal:
            return "Quantity Needed (0-100)"
        }
    }

    var maxQuantity: Int {
        switch tripType {
        case .bulkShopping:
            return 20
        case .eventPlanning, .groupTrip, .potluckMeal:
            return 100
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.bulkSharePrimary)
                            .frame(width: 80, height: 80)
                            .background(Color.bulkSharePrimary.opacity(0.1))
                            .cornerRadius(20)
                        
                        Text(headerTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.bulkShareTextDark)

                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Item Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Item Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.bulkShareTextMedium)
                            
                            TextField("e.g., Kirkland Bread (2-pack)", text: $itemName)
                                .textFieldStyle(BulkShareTextFieldStyle())
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.bulkShareTextMedium)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(relevantCategories, id: \.self) { category in
                                    CategoryCard(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        
                        // Quantity
                        VStack(alignment: .leading, spacing: 8) {
                            Text(quantityLabel)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.bulkShareTextMedium)

                            Menu {
                                ForEach(0...maxQuantity, id: \.self) { count in
                                    Button(action: {
                                        quantity = count
                                    }) {
                                        HStack {
                                            Text("\(count)")
                                            if quantity == count {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("\(quantity)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.bulkShareTextDark)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.bulkShareTextMedium)
                                }
                                .padding()
                                .background(Color.bulkShareBackground)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.bulkShareTextMedium)
                            
                            TextField("Any special details about this item...", text: $notes, axis: .vertical)
                                .textFieldStyle(BulkShareTextFieldStyle())
                                .lineLimit(2, reservesSpace: true)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    
                    // Add Button
                    Button(action: handleAddItem) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Item")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color.bulkSharePrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.bulkSharePrimary)
                }
            }
            .onAppear {
                // Set initial category to first relevant category for trip type
                if let firstCategory = relevantCategories.first {
                    selectedCategory = firstCategory
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !itemName.isEmpty && quantity > 0
    }
    
    private func handleAddItem() {
        let item = TripItem(
            name: itemName,
            quantityAvailable: quantity,
            estimatedPrice: 0.0, // Default price to 0 since we removed price input
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes
        )
        
        onAdd(item)
        dismiss()
    }
}

struct CategoryCard: View {
    let category: ItemCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(category.icon)
                    .font(.title2)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
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

#Preview {
    AddTripItemView(tripType: .bulkShopping) { item in
        print("Added item: \(item.name)")
    }
}
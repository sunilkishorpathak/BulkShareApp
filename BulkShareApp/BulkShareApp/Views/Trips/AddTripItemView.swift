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
    @State private var itemName: String = ""
    @State private var quantity: Int = 1
    @State private var estimatedPrice: String = ""
    @State private var selectedCategory: ItemCategory = .grocery
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (TripItem) -> Void
    
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
                        
                        Text("Add Item to Share")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.bulkShareTextDark)
                        
                        Text("What item do you want to share with your group?")
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
                                ForEach(ItemCategory.allCases, id: \.self) { category in
                                    CategoryCard(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            // Quantity
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quantity Available")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                HStack {
                                    Button(action: { 
                                        if quantity > 1 { quantity -= 1 }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.bulkSharePrimary)
                                            .font(.title2)
                                    }
                                    
                                    Text("\(quantity)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .frame(minWidth: 40)
                                    
                                    Button(action: { quantity += 1 }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.bulkSharePrimary)
                                            .font(.title2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.bulkShareBackground)
                                .cornerRadius(12)
                            }
                            
                            // Price
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price Each")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                HStack {
                                    Text("$")
                                        .font(.title3)
                                        .foregroundColor(.bulkShareTextMedium)
                                    
                                    TextField("0.00", text: $estimatedPrice)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(PlainTextFieldStyle())
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
        }
    }
    
    private var isFormValid: Bool {
        return !itemName.isEmpty && 
               quantity > 0 && 
               !estimatedPrice.isEmpty &&
               Double(estimatedPrice) != nil
    }
    
    private func handleAddItem() {
        guard let price = Double(estimatedPrice) else { return }
        
        let item = TripItem(
            name: itemName,
            quantityAvailable: quantity,
            estimatedPrice: price,
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
    AddTripItemView { item in
        print("Added item: \(item.name)")
    }
}
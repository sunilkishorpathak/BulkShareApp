//
//  AddItemRequestView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct AddItemRequestView: View {
    let tripId: String
    let onAdd: (ItemRequest) -> Void
    
    @State private var itemName: String = ""
    @State private var quantity: Int = 1
    @State private var selectedCategory: ItemCategory = .grocery
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 50))
                            .foregroundColor(.bulkSharePrimary)
                            .frame(width: 80, height: 80)
                            .background(Color.bulkSharePrimary.opacity(0.1))
                            .cornerRadius(20)
                        
                        Text("Request Additional Item")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.bulkShareTextDark)

                        Text("Ask the plan organizer to add an item you need")
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
                            
                            TextField("e.g., Greek Yogurt (Large Container)", text: $itemName)
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
                        
                        // Quantity
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quantity Needed (1-20)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.bulkShareTextMedium)
                            
                            Menu {
                                ForEach(1...20, id: \.self) { count in
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
                            
                            TextField("Any specific details or preferences...", text: $notes, axis: .vertical)
                                .textFieldStyle(BulkShareTextFieldStyle())
                                .lineLimit(2, reservesSpace: true)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    
                    // Request Button
                    Button(action: handleAddRequest) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Request")
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
            .navigationTitle("Request Item")
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
        return !itemName.isEmpty && quantity > 0
    }
    
    private func handleAddRequest() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        let request = ItemRequest(
            tripId: tripId,
            requesterUserId: currentUser.id,
            itemName: itemName,
            quantityRequested: quantity,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes
        )
        
        onAdd(request)
        dismiss()
    }
}

#Preview {
    AddItemRequestView(tripId: "sample-trip") { request in
        print("Added request: \(request.itemName)")
    }
}
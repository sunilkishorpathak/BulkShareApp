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
import FirebaseStorage

struct AddTripItemView: View {
    let tripType: TripType
    @State private var itemName: String = ""
    @State private var quantity: Int = 1
    @State private var selectedCategory: ItemCategory = .grocery
    @State private var notes: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String? = nil
    @State private var showImageSourceOptions = false
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showFullImage = false
    @State private var isUploadingImage = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    let onAdd: (TripItem) -> Void

    var relevantCategories: [ItemCategory] {
        ItemCategory.categoriesFor(tripType: tripType)
    }

    var headerTitle: String {
        switch tripType {
        case .shopping:
            return "Add Item to Share"
        case .events:
            return "Add Event Item"
        case .trips:
            return "Add Supply"
        }
    }

    var headerSubtitle: String {
        switch tripType {
        case .shopping:
            return "What item do you want to share with your group?"
        case .events:
            return "What do you need for the event or potluck?"
        case .trips:
            return "What supplies are needed for the trip?"
        }
    }

    var quantityLabel: String {
        switch tripType {
        case .shopping:
            return "Quantity Available (0-20)"
        case .events, .trips:
            return "Quantity Needed (0-100)"
        }
    }

    var maxQuantity: Int {
        switch tripType {
        case .shopping:
            return 20
        case .events, .trips:
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

                        // Photo Section
                        if selectedImage == nil {
                            // No photo selected - show add button
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Photo (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)

                                Button(action: { showImageSourceOptions = true }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                        Text("Add Photo")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.bulkSharePrimary.opacity(0.1))
                                    .foregroundColor(.bulkSharePrimary)
                                    .cornerRadius(12)
                                }
                            }
                        } else {
                            // Photo selected - show preview
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Photo")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)

                                HStack(spacing: 12) {
                                    // Thumbnail preview
                                    if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            .clipped()
                                            .onTapGesture {
                                                showFullImage = true
                                            }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Photo attached")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Tap to view full size")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    // Remove button
                                    Button(action: {
                                        selectedImage = nil
                                        imageURL = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    
                    // Add Button
                    Button(action: handleAddItem) {
                        HStack {
                            if isUploadingImage {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Uploading...")
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background((isFormValid && !isUploadingImage) ? Color.bulkSharePrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(!isFormValid || isUploadingImage)
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
            .confirmationDialog("Add Photo", isPresented: $showImageSourceOptions, titleVisibility: .visible) {
                Button("Take Photo") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a photo source")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedImage, sourceType: imageSourceType)
            }
            .sheet(isPresented: $showFullImage) {
                FullImageViewer(image: selectedImage, isPresented: $showFullImage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !itemName.isEmpty && quantity > 0
    }

    private func handleAddItem() {
        // Show loading state
        isUploadingImage = true

        // If image selected, upload first
        if let image = selectedImage {
            uploadImage(image) { uploadedURL in
                self.imageURL = uploadedURL
                self.saveItemToDatabase()
            }
        } else {
            // No image, save directly
            saveItemToDatabase()
        }
    }

    private func saveItemToDatabase() {
        let item = TripItem(
            name: itemName,
            quantityAvailable: quantity,
            estimatedPrice: 0.0,
            category: selectedCategory,
            notes: notes.isEmpty ? nil : notes,
            imageURL: imageURL
        )

        isUploadingImage = false
        onAdd(item)
        dismiss()
    }

    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            DispatchQueue.main.async {
                self.isUploadingImage = false
                self.errorMessage = "Failed to process image"
                self.showError = true
            }
            completion(nil)
            return
        }

        // Check image size (limit to 10MB)
        if imageData.count > 10_000_000 {
            DispatchQueue.main.async {
                self.isUploadingImage = false
                self.errorMessage = "Image is too large. Please choose a smaller image (max 10MB)."
                self.showError = true
            }
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference()
        let imageName = "\(UUID().uuidString).jpg"
        let imageRef = storageRef.child("item_images/\(imageName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isUploadingImage = false
                    self.errorMessage = "Error uploading image: \(error.localizedDescription)"
                    self.showError = true
                }
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isUploadingImage = false
                        self.errorMessage = "Error getting download URL: \(error.localizedDescription)"
                        self.showError = true
                    }
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
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

// Full-size image viewer
struct FullImageViewer: View {
    let image: UIImage?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Text("Done")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    AddTripItemView(tripType: .shopping) { item in
        print("Added item: \(item.name)")
    }
}
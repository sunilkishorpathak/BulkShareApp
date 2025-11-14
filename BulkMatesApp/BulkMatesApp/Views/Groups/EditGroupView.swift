//
//  EditGroupView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI
import FirebaseStorage

struct EditGroupView: View {
    @Binding var group: Group
    @Environment(\.dismiss) private var dismiss

    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showImageSourceOptions = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingImage = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Group Icon/Photo Section
                        VStack(spacing: 16) {
                            Text("Group Photo")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkShareTextDark)

                            Button(action: {
                                showImageSourceOptions = true
                            }) {
                                ZStack {
                                    if let selectedImage = selectedImage {
                                        // Show selected image
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.bulkSharePrimary, lineWidth: 3)
                                            )
                                    } else if let iconUrl = group.iconUrl, !iconUrl.isEmpty {
                                        // Show existing custom photo
                                        AsyncImage(url: URL(string: iconUrl)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.bulkSharePrimary, lineWidth: 3)
                                                    )
                                            case .failure(_), .empty:
                                                defaultIconView
                                            @unknown default:
                                                defaultIconView
                                            }
                                        }
                                    } else {
                                        // Show emoji icon fallback
                                        defaultIconView
                                    }

                                    // Camera badge
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "camera.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.bulkSharePrimary)
                                                .background(Color.white.clipShape(Circle()))
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isUploadingImage)

                            if isUploadingImage {
                                ProgressView("Uploading photo...")
                                    .font(.caption)
                            } else {
                                Text("Tap to change group photo")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextMedium)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        // Group Details Form
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Group Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkShareTextDark)

                            // Group Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Group Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)

                                TextField("Enter group name", text: $groupName)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                            }

                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)

                                TextField("What's this group about?", text: $groupDescription, axis: .vertical)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .lineLimit(3, reservesSpace: true)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        // Save Button
                        Button(action: handleSave) {
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
                        .background(isFormValid ? Color.bulkSharePrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(!isFormValid || isSaving)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imageSourceType)
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showImageSourceOptions, titleVisibility: .visible) {
                Button("Take Photo") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                groupName = group.name
                groupDescription = group.description
            }
        }
    }

    private var defaultIconView: some View {
        ZStack {
            Circle()
                .fill(Color.bulkSharePrimary.opacity(0.1))
                .frame(width: 100, height: 100)

            Text(group.icon)
                .font(.system(size: 50))
        }
        .overlay(
            Circle()
                .stroke(Color.bulkSharePrimary, lineWidth: 3)
        )
    }

    private var isFormValid: Bool {
        return !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleSave() {
        isSaving = true

        Task {
            do {
                // Upload image if a new one was selected
                if let image = selectedImage {
                    isUploadingImage = true
                    let imageUrl = try await uploadGroupImage(image)
                    group.iconUrl = imageUrl
                    isUploadingImage = false
                }

                // Update group details
                group.name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                group.description = groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)

                // Save to Firestore
                try await FirebaseManager.shared.updateGroup(group)

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    isUploadingImage = false
                    errorMessage = "Failed to update group: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func uploadGroupImage(_ image: UIImage) async throws -> String {
        // Resize image to max 1024px
        let resizedImage = resizeImage(image, maxDimension: 1024)

        // Compress with adaptive quality
        var compressionQuality: CGFloat = 0.8
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)

        // Reduce quality if still over 2MB
        while let data = imageData, data.count > 2_000_000 && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }

        guard let finalImageData = imageData else {
            throw NSError(domain: "EditGroupView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }

        // Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let imageName = "\(group.id).jpg"
        let imageRef = storageRef.child("group_images/\(imageName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await imageRef.putDataAsync(finalImageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await imageRef.downloadURL()
        return downloadURL.absoluteString
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

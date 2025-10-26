//
//  AddActivityView.swift
//  BulkMatesApp
//
//  Sheet for adding new activity to a trip
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct AddActivityView: View {
    let trip: Trip
    let onActivityAdded: () -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var selectedType: ActivityType = .comment
    @State private var message: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploading = false

    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private var currentUser: User? {
        firebaseManager.currentUser
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you want to share?")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        activityTypeButton(.comment, icon: "💬", title: "Comment")
                        activityTypeButton(.photo, icon: "📷", title: "Photo")
                        activityTypeButton(.receipt, icon: "📄", title: "Receipt")
                        activityTypeButton(.location, icon: "📍", title: "Location")
                    }
                    .padding(.horizontal)
                }

                // Message input
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedType == .comment ? "Message" : "Message (Optional)")
                        .font(.headline)
                        .padding(.horizontal)

                    TextEditor(text: $message)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }

                // Image preview
                if let image = selectedImage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Selected \(selectedType == .receipt ? "Receipt" : "Photo")")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Spacer()

                            Button(action: {
                                selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }

                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 4) {
                        tipText("Share updates about the plan")
                        tipText("Upload receipts for transparency")
                        tipText("Post photos from the event")
                        tipText("Coordinate timing and logistics")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Add to Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: postActivity) {
                        if isUploading {
                            ProgressView()
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isUploading || !canPost)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedImage, sourceType: imageSourceType)
            }
        }
    }

    func activityTypeButton(_ type: ActivityType, icon: String, title: String) -> some View {
        Button(action: {
            selectedType = type

            if type == .photo || type == .receipt {
                imageSourceType = type == .photo ? .camera : .photoLibrary
                showImagePicker = true
            }
        }) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                selectedType == type ? Color.bulkSharePrimary.opacity(0.1) : Color.gray.opacity(0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedType == type ? Color.bulkSharePrimary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }

    func tipText(_ text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 4, height: 4)
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    var canPost: Bool {
        if selectedType == .comment {
            return !message.isEmpty
        } else if selectedType == .photo || selectedType == .receipt {
            return selectedImage != nil
        }
        return !message.isEmpty
    }

    func postActivity() {
        isUploading = true

        if selectedType == .comment || selectedType == .location {
            // Post text-only activity
            let activity = PlanActivity(
                tripId: trip.id,
                userId: currentUserId,
                userName: currentUser?.name ?? "Unknown",
                userProfileImageURL: currentUser?.profileImageURL,
                type: selectedType,
                message: message.isEmpty ? nil : message,
                location: selectedType == .location ? message : nil,
                timestamp: Date()
            )

            saveActivity(activity)
        } else if selectedImage != nil {
            // Upload image first, then post activity
            uploadImageAndPost()
        } else {
            isUploading = false
        }
    }

    func uploadImageAndPost() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            isUploading = false
            return
        }

        let storageRef = Storage.storage().reference()
        let imageName = "\(selectedType.rawValue)_\(UUID().uuidString).jpg"
        let imageRef = storageRef.child("trip_activities/\(trip.id)/\(imageName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                isUploading = false
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    isUploading = false
                    return
                }

                if let urlString = url?.absoluteString {
                    let activity = PlanActivity(
                        tripId: trip.id,
                        userId: currentUserId,
                        userName: currentUser?.name ?? "Unknown",
                        userProfileImageURL: currentUser?.profileImageURL,
                        type: selectedType,
                        message: message.isEmpty ? nil : message,
                        imageURL: urlString,
                        imageType: selectedType.rawValue,
                        timestamp: Date()
                    )

                    saveActivity(activity)
                } else {
                    isUploading = false
                }
            }
        }
    }

    func saveActivity(_ activity: PlanActivity) {
        let db = Firestore.firestore()

        do {
            let activityData = try Firestore.Encoder().encode(activity)

            db.collection("trips").document(trip.id)
                .collection("activities")
                .document(activity.id)
                .setData(activityData) { error in
                    isUploading = false

                    if let error = error {
                        print("Error saving activity: \(error)")
                    } else {
                        // Update trip's activity count
                        db.collection("trips").document(trip.id).updateData([
                            "activityCount": FieldValue.increment(Int64(1)),
                            "lastActivityTimestamp": Timestamp(date: Date())
                        ])

                        onActivityAdded()
                        dismiss()
                    }
                }
        } catch {
            print("Error encoding activity: \(error)")
            isUploading = false
        }
    }
}

#Preview {
    AddActivityView(trip: Trip.sampleTrips[0], onActivityAdded: {})
        .environmentObject(FirebaseManager.shared)
}

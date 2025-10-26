//
//  PlanActivityFeedView.swift
//  BulkMatesApp
//
//  Activity feed for trips/plans
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct PlanActivityFeedView: View {
    let trip: Trip
    @State private var activities: [PlanActivity] = []
    @State private var isLoading = false
    @State private var commentText = ""
    @State private var showAddActivity = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var uploadType: ActivityType = .photo
    @State private var isUploading = false

    @State private var selectedActivity: PlanActivity?
    @State private var showFullScreenImage = false

    @EnvironmentObject var firebaseManager: FirebaseManager

    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private var currentUser: User? {
        firebaseManager.currentUser
    }

    var body: some View {
        VStack(spacing: 0) {
            // Activity feed
            if activities.isEmpty && !isLoading {
                emptyStateView
            } else if isLoading && activities.isEmpty {
                ProgressView("Loading activities...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activities) { activity in
                            ActivityItemView(
                                activity: activity,
                                currentUserId: currentUserId,
                                onLike: { likeActivity(activity) },
                                onImageTap: {
                                    selectedActivity = activity
                                    showFullScreenImage = true
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }

            Divider()

            // Comment input area
            commentInputArea
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddActivity = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.bulkSharePrimary)
                }
            }
        }
        .onAppear {
            loadActivities()
        }
        .sheet(isPresented: $showAddActivity) {
            AddActivityView(
                trip: trip,
                onActivityAdded: {
                    loadActivities()
                }
            )
            .environmentObject(firebaseManager)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $selectedImage, sourceType: imageSourceType)
                .onDisappear {
                    if let image = selectedImage {
                        uploadImage(image)
                    }
                }
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let activity = selectedActivity {
                FullScreenImageView(activity: activity, isPresented: $showFullScreenImage)
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Activity Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)

            Text("Start a conversation or share updates about this plan")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    var commentInputArea: some View {
        HStack(spacing: 12) {
            // Comment text field
            HStack {
                TextField("Add a comment...", text: $commentText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Attachment buttons
            HStack(spacing: 8) {
                Button(action: {
                    uploadType = .photo
                    imageSourceType = .camera
                    showImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.bulkSharePrimary)
                        .clipShape(Circle())
                }

                Button(action: {
                    uploadType = .receipt
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.bulkSharePrimary)
                        .clipShape(Circle())
                }
            }

            // Send button
            Button(action: postComment) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(commentText.isEmpty ? .gray : .bulkSharePrimary)
            }
            .disabled(commentText.isEmpty || isUploading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    func loadActivities() {
        isLoading = true

        let db = Firestore.firestore()
        db.collection("trips").document(trip.id)
            .collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                isLoading = false

                if let error = error {
                    print("Error loading activities: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.activities = documents.compactMap { doc in
                    try? doc.data(as: PlanActivity.self)
                }
            }
    }

    func postComment() {
        guard !commentText.isEmpty else { return }

        isUploading = true

        let activity = PlanActivity(
            tripId: trip.id,
            userId: currentUserId,
            userName: currentUser?.name ?? "Unknown",
            userProfileImageURL: currentUser?.profileImageURL,
            type: .comment,
            message: commentText,
            timestamp: Date()
        )

        saveActivity(activity)

        // Clear input
        commentText = ""
    }

    func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            isUploading = false
            return
        }

        isUploading = true

        let storageRef = Storage.storage().reference()
        let imageName = "\(uploadType.rawValue)_\(UUID().uuidString).jpg"
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
                        type: uploadType,
                        message: uploadType == .receipt ? "Uploaded receipt" : nil,
                        imageURL: urlString,
                        imageType: uploadType.rawValue,
                        timestamp: Date()
                    )

                    saveActivity(activity)
                } else {
                    isUploading = false
                }
            }
        }

        // Clear selected image
        selectedImage = nil
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
                        // Update trip's activity count and timestamp
                        db.collection("trips").document(trip.id).updateData([
                            "activityCount": FieldValue.increment(Int64(1)),
                            "lastActivityTimestamp": Timestamp(date: Date())
                        ])

                        // Reload activities
                        loadActivities()
                    }
                }
        } catch {
            print("Error encoding activity: \(error)")
            isUploading = false
        }
    }

    func likeActivity(_ activity: PlanActivity) {
        var updatedActivity = activity

        if updatedActivity.likes.contains(currentUserId) {
            // Unlike
            updatedActivity.likes.removeAll { $0 == currentUserId }
        } else {
            // Like
            updatedActivity.likes.append(currentUserId)
        }

        let db = Firestore.firestore()
        db.collection("trips").document(trip.id)
            .collection("activities")
            .document(activity.id)
            .updateData(["likes": updatedActivity.likes]) { error in
                if error == nil {
                    loadActivities()
                }
            }
    }
}

#Preview {
    NavigationView {
        PlanActivityFeedView(trip: Trip.sampleTrips[0])
            .environmentObject(FirebaseManager.shared)
    }
}

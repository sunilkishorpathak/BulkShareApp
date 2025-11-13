//
//  UserProfileView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct UserProfileView: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isDeleting = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingAcknowledgments = false

    // Profile image states
    @State private var selectedProfileImage: UIImage? = nil
    @State private var showProfileImageOptions = false
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingImage = false
    @State private var showRemovePhotoConfirmation = false

    // Address states
    @State private var showEditAddress = false
    @State private var addressVisibility: AddressVisibility = .fullAddress

    // Security states
    @State private var biometricEnabled = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""

    // Computed properties for safe data access
    private var userEmail: String {
        return firebaseManager.currentUser?.email ?? 
               Auth.auth().currentUser?.email ?? 
               "No email available"
    }
    
    private var userEmailVerified: String {
        // Check both Firestore and Firebase Auth
        let firestoreVerified = firebaseManager.currentUser?.isEmailVerified ?? false
        let authVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        return (firestoreVerified || authVerified) ? "Yes" : "No"
    }
    
    private var userName: String {
        return firebaseManager.currentUser?.displayName ??
               Auth.auth().currentUser?.displayName ??
               "User"
    }

    // MARK: - View Components

    private var mainContent: some View {
        ZStack {
            Color.bulkShareBackground.ignoresSafeArea()

            if isDeleting {
                DeletingAccountView()
            } else {
                profileScrollView
            }
        }
    }

    private var profileScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                accountSection
                addressSection
                securitySection
                privacySection
                dangerZoneSection
                accountInfoSection
            }
            .padding()
        }
    }

    private var profileHeader: some View {
        EditableProfileHeaderView(
            user: firebaseManager.currentUser,
            selectedImage: $selectedProfileImage,
            isUploading: isUploadingImage,
            onEditPhoto: { showProfileImageOptions = true },
            onRemovePhoto: { showRemovePhotoConfirmation = true }
        )
    }

    private var accountSection: some View {
        SettingsSection(title: "Account") {
            ProfileSettingsRow(
                icon: "person.circle",
                title: "Email",
                value: userEmail,
                action: nil
            )

            ProfileSettingsRow(
                icon: "checkmark.shield",
                title: "Email Verified",
                value: userEmailVerified,
                action: nil
            )
        }
    }

    private var addressSection: some View {
        SettingsSection(title: "Address") {
            ProfileSettingsRow(
                icon: "location.circle",
                title: "Location",
                value: firebaseManager.currentUser?.address?.shortAddress ?? "Add your address",
                action: { showEditAddress = true }
            )

            if firebaseManager.currentUser?.address != nil {
                addressVisibilityPicker
            }
        }
    }

    private var addressVisibilityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eye.circle")
                    .foregroundColor(.bulkSharePrimary)
                    .frame(width: 24)

                Text("Who can see")
                    .font(.body)
                    .foregroundColor(.bulkShareTextDark)

                Spacer()

                Picker("", selection: $addressVisibility) {
                    ForEach(AddressVisibility.allCases, id: \.self) { visibility in
                        Text(visibility.rawValue).tag(visibility)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.bulkSharePrimary)
            }
            .padding()

            Text(addressVisibility.description)
                .font(.caption)
                .foregroundColor(.bulkShareTextMedium)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    private var securitySection: some View {
        SettingsSection(title: "Security") {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: biometricIconName)
                        .foregroundColor(.bulkSharePrimary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(biometricLabel)
                            .font(.body)
                            .foregroundColor(.bulkShareTextDark)

                        if BiometricAuth.shared.isAvailable() {
                            Text("Unlock app with biometrics")
                                .font(.caption)
                                .foregroundColor(.bulkShareTextMedium)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $biometricEnabled)
                        .labelsHidden()
                        .tint(.bulkSharePrimary)
                        .disabled(!BiometricAuth.shared.isAvailable())
                }
                .padding()
            }
        }
    }

    private var privacySection: some View {
        SettingsSection(title: "Privacy & Data") {
            ProfileSettingsRow(
                icon: "doc.text",
                title: "Privacy Policy",
                value: "",
                action: { showingPrivacyPolicy = true }
            )

            ProfileSettingsRow(
                icon: "doc.plaintext",
                title: "Terms of Service",
                value: "",
                action: { showingTermsOfService = true }
            )

            ProfileSettingsRow(
                icon: "hand.thumbsup",
                title: "Acknowledgments",
                value: "",
                action: { showingAcknowledgments = true }
            )
        }
    }

    private var dangerZoneSection: some View {
        SettingsSection(title: "Danger Zone") {
            DangerousSettingsRow(
                icon: "trash",
                title: "Delete Account",
                subtitle: "Permanently delete your account and all data",
                action: {
                    showingDeleteConfirmation = true
                }
            )
        }
    }

    private var accountInfoSection: some View {
        VStack(spacing: 8) {
            if let user = firebaseManager.currentUser {
                Text("Account created: \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            } else {
                Text("Loading account information...")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
                    .italic()
            }
        }
        .padding(.top, 20)
    }

    var body: some View {
        NavigationView {
            mainContent
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    handleDeleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data, groups, and plans will be permanently deleted.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingAcknowledgments) {
                AcknowledgmentsView()
            }
            .sheet(isPresented: $showEditAddress) {
                if let user = firebaseManager.currentUser {
                    EditAddressView(user: user)
                        .environmentObject(firebaseManager)
                }
            }
            .confirmationDialog("Profile Picture", isPresented: $showProfileImageOptions, titleVisibility: .visible) {
                Button("Take Photo") {
                    imageSourceType = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    imageSourceType = .photoLibrary
                    showImagePicker = true
                }
                if firebaseManager.currentUser?.profileImageURL != nil {
                    Button("Remove Photo", role: .destructive) {
                        showRemovePhotoConfirmation = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Update your profile picture")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedProfileImage, sourceType: imageSourceType)
                    .onDisappear {
                        if selectedProfileImage != nil {
                            uploadProfileImage()
                        }
                    }
            }
            .alert("Remove Profile Picture?", isPresented: $showRemovePhotoConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    removeProfileImage()
                }
            } message: {
                Text("Your profile will show your initials instead")
            }
            .alert("Biometric Error", isPresented: $showBiometricError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(biometricErrorMessage)
            }
            .onChange(of: addressVisibility) { _, newValue in
                updateAddressVisibility(newValue)
            }
            .onChange(of: biometricEnabled) { _, newValue in
                if newValue {
                    enableBiometric()
                } else {
                    disableBiometric()
                }
            }
            .onAppear {
                loadUserSettings()
            }
        }
    }

    // MARK: - Computed Properties

    private var biometricIconName: String {
        switch BiometricAuth.shared.biometricType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }

    private var biometricLabel: String {
        switch BiometricAuth.shared.biometricType() {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric not available"
        }
    }

    // MARK: - Helper Functions

    private func loadUserSettings() {
        if let user = firebaseManager.currentUser {
            addressVisibility = user.addressVisibility
            biometricEnabled = user.biometricEnabled

            // Load from UserDefaults as well for biometric
            if let currentUserId = Auth.auth().currentUser?.uid {
                let savedBiometric = UserDefaults.standard.bool(forKey: "biometricEnabled_\(currentUserId)")
                biometricEnabled = savedBiometric
            }
        }
    }

    private func updateAddressVisibility(_ visibility: AddressVisibility) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).updateData([
            "addressVisibility": visibility.rawValue
        ]) { error in
            if let error = error {
                print("Error updating address visibility: \(error)")
            } else {
                // Update local user object
                if var user = firebaseManager.currentUser {
                    user.addressVisibility = visibility
                    firebaseManager.currentUser = user
                }
            }
        }
    }

    private func enableBiometric() {
        BiometricAuth.shared.authenticate(reason: "Enable biometric authentication for BulkMates") { success, error in
            if success {
                // Update in Firestore
                if let currentUserId = Auth.auth().currentUser?.uid {
                    let db = Firestore.firestore()
                    db.collection("users").document(currentUserId).updateData([
                        "biometricEnabled": true
                    ])

                    // Save to UserDefaults
                    UserDefaults.standard.set(true, forKey: "biometricEnabled_\(currentUserId)")

                    // Update local user object
                    if var user = firebaseManager.currentUser {
                        user.biometricEnabled = true
                        firebaseManager.currentUser = user
                    }
                }
            } else {
                // Reset toggle if authentication failed
                DispatchQueue.main.async {
                    self.biometricEnabled = false
                    if let error = error {
                        self.biometricErrorMessage = error.localizedDescription
                        self.showBiometricError = true
                    }
                }
            }
        }
    }

    private func disableBiometric() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).updateData([
            "biometricEnabled": false
        ])

        // Remove from UserDefaults
        UserDefaults.standard.set(false, forKey: "biometricEnabled_\(currentUserId)")

        // Update local user object
        if var user = firebaseManager.currentUser {
            user.biometricEnabled = false
            firebaseManager.currentUser = user
        }
    }
    
    private func handleDeleteAccount() {
        isDeleting = true

        Task {
            let result = await firebaseManager.deleteAccount()

            DispatchQueue.main.async {
                self.isDeleting = false

                switch result {
                case .success:
                    // Account deleted successfully, user will be automatically signed out
                    // and redirected to login screen by RootView
                    break
                case .failure(let error):
                    self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }

    private func uploadProfileImage() {
        guard let image = selectedProfileImage else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        isUploadingImage = true

        // Resize image to max 1024px to reduce file size
        let resizedImage = resizeImage(image: image, maxDimension: 1024)

        // Compress image with quality adjustment for target size
        var compressionQuality: CGFloat = 0.7
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)

        // If still over 2MB, compress more aggressively
        while let data = imageData, data.count > 2_000_000 && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }

        guard let finalImageData = imageData else {
            DispatchQueue.main.async {
                self.isUploadingImage = false
                self.errorMessage = "Failed to process image. Please try a different photo."
                self.showingError = true
            }
            return
        }

        #if DEBUG
        print("📸 Uploading profile image: \(finalImageData.count / 1024)KB with quality: \(compressionQuality)")
        #endif

        let storageRef = Storage.storage().reference()
        let imageName = "\(currentUserId).jpg"
        let imageRef = storageRef.child("profile_images/\(imageName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=31536000" // Cache for 1 year

        // Upload the image
        imageRef.putData(finalImageData, metadata: metadata) { uploadMetadata, error in
            if let error = error {
                #if DEBUG
                print("❌ Error uploading profile image: \(error.localizedDescription)")
                #endif
                DispatchQueue.main.async {
                    self.isUploadingImage = false
                    self.errorMessage = "Failed to upload profile picture. Please check your connection and try again."
                    self.showingError = true
                }
                return
            }

            #if DEBUG
            print("✅ Profile image uploaded successfully")
            #endif

            // Get download URL immediately after successful upload
            imageRef.downloadURL { url, error in
                if let error = error {
                    #if DEBUG
                    print("❌ Error getting download URL: \(error.localizedDescription)")
                    #endif
                    DispatchQueue.main.async {
                        self.isUploadingImage = false
                        self.errorMessage = "Upload completed but failed to get image URL. Please try again."
                        self.showingError = true
                    }
                    return
                }

                guard let downloadURL = url else {
                    DispatchQueue.main.async {
                        self.isUploadingImage = false
                        self.errorMessage = "Failed to get image URL. Please try again."
                        self.showingError = true
                    }
                    return
                }

                #if DEBUG
                print("✅ Got download URL: \(downloadURL.absoluteString)")
                #endif

                // Update Firestore with the new profile image URL
                self.updateUserProfileImage(downloadURL.absoluteString)
            }
        }
    }

    // Helper function to resize image
    private func resizeImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            // Landscape
            newSize = CGSize(width: min(maxDimension, size.width),
                           height: min(maxDimension, size.width) / aspectRatio)
        } else {
            // Portrait or square
            newSize = CGSize(width: min(maxDimension, size.height) * aspectRatio,
                           height: min(maxDimension, size.height))
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func updateUserProfileImage(_ imageURL: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isUploadingImage = false
                self.errorMessage = "User not authenticated"
                self.showingError = true
            }
            return
        }

        #if DEBUG
        print("💾 Updating Firestore with profile image URL...")
        #endif

        // Update Firestore
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).updateData([
            "profileImageURL": imageURL
        ]) { error in
            DispatchQueue.main.async {
                self.isUploadingImage = false

                if let error = error {
                    #if DEBUG
                    print("❌ Error updating Firestore: \(error.localizedDescription)")
                    #endif
                    self.errorMessage = "Profile picture uploaded but failed to save. Please try again."
                    self.showingError = true
                } else {
                    #if DEBUG
                    print("✅ Profile image URL saved to Firestore")
                    #endif

                    // Update local user object
                    if var user = self.firebaseManager.currentUser {
                        user.profileImageURL = imageURL
                        self.firebaseManager.currentUser = user
                    }
                    self.selectedProfileImage = nil

                    // Show success message
                    self.successMessage = "Profile picture updated successfully!"
                    self.showingSuccess = true
                }
            }
        }
    }

    private func removeProfileImage() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }

        isUploadingImage = true

        #if DEBUG
        print("🗑️ Removing profile image...")
        #endif

        // Remove from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).updateData([
            "profileImageURL": FieldValue.delete()
        ]) { error in
            DispatchQueue.main.async {
                self.isUploadingImage = false

                if let error = error {
                    #if DEBUG
                    print("❌ Error removing profile image: \(error.localizedDescription)")
                    #endif
                    self.errorMessage = "Failed to remove profile picture. Please try again."
                    self.showingError = true
                } else {
                    #if DEBUG
                    print("✅ Profile image removed successfully")
                    #endif

                    // Update local state
                    if var user = self.firebaseManager.currentUser {
                        user.profileImageURL = nil
                        self.firebaseManager.currentUser = user
                    }
                    self.selectedProfileImage = nil

                    // Show success message
                    self.successMessage = "Profile picture removed"
                    self.showingSuccess = true
                }
            }
        }

        // Note: We keep the image in Storage for potential re-use
        // If you want to delete from Storage, uncomment below:
        /*
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("profile_images/\(currentUserId).jpg")
        imageRef.delete { error in
            if let error = error {
                #if DEBUG
                print("⚠️ Warning: Could not delete image from Storage: \(error.localizedDescription)")
                #endif
            }
        }
        */
    }
}

// MARK: - Supporting Views

struct EditableProfileHeaderView: View {
    let user: User?
    @Binding var selectedImage: UIImage?
    let isUploading: Bool
    let onEditPhoto: () -> Void
    let onRemovePhoto: () -> Void

    private var userName: String {
        user?.displayName ?? "User"
    }

    private var userEmail: String {
        user?.email ?? "No email"
    }

    private var userInitials: String {
        guard let user = user else { return "U" }
        return user.initials
    }

    var body: some View {
        VStack(spacing: 16) {
            // Profile Image / Initials with Edit Button
            ZStack(alignment: .bottomTrailing) {
                // Main profile image
                ZStack {
                    if let selectedImage = selectedImage {
                        // Show newly selected image
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else if let imageURL = user?.profileImageURL, let url = URL(string: imageURL) {
                        // Show current profile image from URL
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            case .failure(_), .empty:
                                defaultImageView
                            @unknown default:
                                defaultImageView
                            }
                        }
                    } else {
                        // Show default initials
                        defaultImageView
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.bulkSharePrimary.opacity(0.2), lineWidth: 2)
                )
                .overlay(
                    ZStack {
                        if isUploading {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                )

                // Edit button overlay
                Button(action: onEditPhoto) {
                    ZStack {
                        Circle()
                            .fill(Color.bulkSharePrimary)
                            .frame(width: 36, height: 36)

                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                }
                .offset(x: -4, y: -4)
                .disabled(isUploading)
            }

            // User Name and Email
            VStack(spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)

                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
            }
        }
        .padding(.vertical)
    }

    private var defaultImageView: some View {
        ZStack {
            Circle()
                .fill(Color.bulkSharePrimary.opacity(0.1))
                .frame(width: 120, height: 120)

            Text(userInitials)
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.bulkSharePrimary)
        }
    }
}

struct ProfileHeaderView: View {
    let userName: String
    let userEmail: String

    private var userInitials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }

    var body: some View {
        VStack(spacing: 16) {
            // Profile Image / Initials
            ZStack {
                Circle()
                    .fill(Color.bulkSharePrimary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Text(userInitials)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkSharePrimary)
            }

            // User Name
            VStack(spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)

                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
            }
        }
        .padding(.vertical)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.bulkShareTextDark)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.bulkSharePrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.bulkShareTextDark)
                
                if !value.isEmpty {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
            }
            
            Spacer()
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextLight)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

struct DangerousSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.red)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.bulkShareTextLight)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct DeletingAccountView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                .scaleEffect(1.5)
            
            Text("Deleting account...")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(FirebaseManager.shared)
}
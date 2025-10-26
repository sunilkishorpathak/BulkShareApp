//
//  ClaimItemView.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI

struct ClaimItemView: View {
    let item: TripItem
    let existingClaims: [ItemClaim]
    let existingComments: [ItemComment]
    let tripShopperId: String
    let onClaim: (Int) -> Void
    let onToggleCompletion: (ItemClaim) -> Void
    let onAddComment: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var quantityToClaim: Int = 1
    @State private var claimerUsers: [String: User] = [:]
    @State private var commenterUsers: [String: User] = [:]
    @State private var isLoadingNames = true
    @State private var newCommentText: String = ""
    @FocusState private var isCommentFieldFocused: Bool

    private var currentUserId: String? {
        FirebaseManager.shared.currentUser?.id
    }

    private var claimedQuantity: Int {
        item.claimedQuantity(claims: existingClaims)
    }

    private var remainingQuantity: Int {
        item.remainingQuantity(claims: existingClaims)
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

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Item Header
                        VStack(spacing: 16) {
                            // Icon
                            Text(item.category.icon)
                                .font(.system(size: 50))
                                .frame(width: 80, height: 80)
                                .background(Color.bulkSharePrimary.opacity(0.1))
                                .cornerRadius(20)

                            // Item Name
                            Text(item.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.bulkShareTextDark)
                                .multilineTextAlignment(.center)

                            // Category
                            Text(item.category.displayName)
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextMedium)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        // Quantity Progress Card
                        VStack(spacing: 16) {
                            HStack {
                                Text("Quantity Status")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                                Spacer()
                            }

                            // Progress Info
                            HStack(alignment: .bottom, spacing: 8) {
                                Text("\(claimedQuantity)")
                                    .font(.system(size: 36))
                                    .fontWeight(.bold)
                                    .foregroundColor(progressColor)

                                Text("/ \(item.totalQuantity)")
                                    .font(.title3)
                                    .foregroundColor(.bulkShareTextMedium)
                                    .padding(.bottom, 6)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(remainingQuantity) remaining")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(remainingQuantity > 0 ? .bulkShareSuccess : .red)

                                    Text("\(Int(progressPercentage * 100))% claimed")
                                        .font(.caption)
                                        .foregroundColor(.bulkShareTextMedium)
                                }
                            }

                            // Progress Bar
                            QuantityProgressBar(
                                claimedQuantity: claimedQuantity,
                                totalQuantity: item.totalQuantity
                            )
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        // Existing Claims
                        if !existingClaims.isEmpty {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Who's Bringing What")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.bulkShareTextDark)
                                    Spacer()
                                }

                                VStack(spacing: 12) {
                                    ForEach(existingClaims) { claim in
                                        ClaimDetailRow(
                                            claim: claim,
                                            claimerUser: claimerUsers[claim.claimerUserId],
                                            canToggleCompletion: canUserToggleCompletion(claim: claim),
                                            onToggleCompletion: {
                                                onToggleCompletion(claim)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        }

                        // Claim Input Section
                        if remainingQuantity > 0 {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("How many will you bring?")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.bulkShareTextDark)
                                    Spacer()
                                }

                                // Quantity Selector
                                HStack {
                                    Button(action: {
                                        if quantityToClaim > 1 {
                                            quantityToClaim -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(quantityToClaim > 1 ? .bulkSharePrimary : .gray)
                                    }
                                    .disabled(quantityToClaim <= 1)

                                    Spacer()

                                    VStack(spacing: 4) {
                                        Text("\(quantityToClaim)")
                                            .font(.system(size: 48))
                                            .fontWeight(.bold)
                                            .foregroundColor(.bulkSharePrimary)

                                        Text("pieces")
                                            .font(.caption)
                                            .foregroundColor(.bulkShareTextMedium)
                                    }

                                    Spacer()

                                    Button(action: {
                                        if quantityToClaim < remainingQuantity {
                                            quantityToClaim += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(quantityToClaim < remainingQuantity ? .bulkSharePrimary : .gray)
                                    }
                                    .disabled(quantityToClaim >= remainingQuantity)
                                }
                                .padding()
                                .background(Color.bulkSharePrimary.opacity(0.05))
                                .cornerRadius(12)

                                // Validation Message
                                if quantityToClaim > remainingQuantity {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("Only \(remainingQuantity) pieces remaining")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        } else {
                            // Fully Claimed
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)

                                Text("Fully Claimed")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.bulkShareTextDark)

                                Text("All quantities for this item have been claimed")
                                    .font(.subheadline)
                                    .foregroundColor(.bulkShareTextMedium)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(30)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        }

                        // Item Notes
                        if let notes = item.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.bulkSharePrimary)
                                    Text("Item Notes")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.bulkShareTextMedium)
                                    Spacer()
                                }

                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(.bulkShareTextDark)
                            }
                            .padding()
                            .background(Color.bulkSharePrimary.opacity(0.05))
                            .cornerRadius(12)
                        }

                        // Comments Section
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundColor(.bulkShareInfo)
                                Text("Comments & Coordination")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                                Spacer()
                            }

                            // Comments List
                            if existingComments.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "bubble.left")
                                        .font(.title2)
                                        .foregroundColor(.bulkShareTextLight)

                                    Text("No comments yet")
                                        .font(.subheadline)
                                        .foregroundColor(.bulkShareTextMedium)

                                    Text("Be the first to add a comment")
                                        .font(.caption)
                                        .foregroundColor(.bulkShareTextLight)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(20)
                                .background(Color.bulkShareBackground)
                                .cornerRadius(12)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(existingComments.sorted { $0.createdAt < $1.createdAt }) { comment in
                                        CommentRow(
                                            comment: comment,
                                            commenterUser: commenterUsers[comment.userId]
                                        )
                                    }
                                }
                            }

                            // Comment Input Field
                            VStack(spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    // User Profile Picture
                                    if let currentUser = FirebaseManager.shared.currentUser {
                                        ProfileImageView(user: currentUser, size: 32)
                                    }

                                    // Text Field
                                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(Color.bulkShareBackground)
                                        .cornerRadius(12)
                                        .focused($isCommentFieldFocused)
                                        .lineLimit(1...4)

                                    // Send Button
                                    if !newCommentText.isEmpty {
                                        Button(action: handleAddComment) {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.bulkSharePrimary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)

                        Spacer(minLength: 100)
                    }
                    .padding()
                }

                // Bottom Buttons
                if remainingQuantity > 0 {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Cancel")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.bulkShareBorder, lineWidth: 1)
                                    )
                            }

                            Button(action: {
                                onClaim(quantityToClaim)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Claim \(quantityToClaim)")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.bulkSharePrimary)
                                .cornerRadius(16)
                            }
                            .disabled(quantityToClaim > remainingQuantity)
                        }
                        .padding()
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    }
                }
            }
            .navigationTitle("Claim Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            .onAppear {
                loadClaimerNames()
                loadCommenterNames()
            }
        }
    }

    private func canUserToggleCompletion(claim: ItemClaim) -> Bool {
        guard let userId = currentUserId else { return false }
        // User can toggle if they are the claimer or trip creator
        return claim.claimerUserId == userId || tripShopperId == userId
    }

    private func handleAddComment() {
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        onAddComment(trimmedText)
        newCommentText = ""
        isCommentFieldFocused = false
    }

    private func loadClaimerNames() {
        Task {
            var users: [String: User] = [:]
            for claim in existingClaims {
                do {
                    let user = try await FirebaseManager.shared.getUser(uid: claim.claimerUserId)
                    users[claim.claimerUserId] = user
                } catch {
                    print("Error loading claimer: \(error)")
                }
            }

            DispatchQueue.main.async {
                self.claimerUsers = users
                self.isLoadingNames = false
            }
        }
    }

    private func loadCommenterNames() {
        Task {
            var users: [String: User] = [:]
            for comment in existingComments {
                do {
                    let user = try await FirebaseManager.shared.getUser(uid: comment.userId)
                    users[comment.userId] = user
                } catch {
                    print("Error loading commenter: \(error)")
                }
            }

            DispatchQueue.main.async {
                self.commenterUsers = users
            }
        }
    }
}

// MARK: - Supporting Components

struct QuantityProgressBar: View {
    let claimedQuantity: Int
    let totalQuantity: Int

    private var progressPercentage: Double {
        guard totalQuantity > 0 else { return 0 }
        return Double(claimedQuantity) / Double(totalQuantity)
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

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.bulkShareBackground)
                    .frame(height: 12)

                // Progress
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [progressColor, progressColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(progressPercentage, 1.0)), height: 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressPercentage)
            }
        }
        .frame(height: 12)
    }
}

struct ClaimDetailRow: View {
    let claim: ItemClaim
    let claimerUser: User?
    let canToggleCompletion: Bool
    let onToggleCompletion: () -> Void

    private var claimerName: String {
        claimerUser?.name ?? "Loading..."
    }

    var statusIcon: String {
        if claim.isCompleted {
            return "checkmark.square.fill"
        }
        switch claim.status {
        case .accepted: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .rejected: return "xmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        }
    }

    var statusColor: Color {
        if claim.isCompleted {
            return .green
        }
        switch claim.status {
        case .accepted: return .green
        case .pending: return .orange
        case .rejected: return .red
        case .cancelled: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let user = claimerUser {
                ProfileImageView(user: user, size: 40)
                    .opacity(claim.isCompleted ? 0.5 : 1.0)
            } else {
                // Placeholder while loading
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
            }

            // Name and Quantity
            VStack(alignment: .leading, spacing: 4) {
                Text(claimerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(claim.isCompleted ? .bulkShareTextLight : .bulkShareTextDark)
                    .strikethrough(claim.isCompleted, color: .bulkShareTextLight)

                HStack(spacing: 4) {
                    Text("\(claim.quantityClaimed) pieces")
                        .font(.caption)
                        .foregroundColor(claim.isCompleted ? .bulkShareTextLight : .bulkShareTextMedium)
                        .strikethrough(claim.isCompleted, color: .bulkShareTextLight)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)

                    if claim.isCompleted {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text(claim.status.displayName)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
            }

            Spacer()

            // Completion Toggle or Status Icon
            if canToggleCompletion && claim.status == .accepted {
                Button(action: onToggleCompletion) {
                    Image(systemName: claim.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(claim.isCompleted ? .green : .bulkShareTextMedium)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(statusColor.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CommentRow: View {
    let comment: ItemComment
    let commenterUser: User?

    private var commenterName: String {
        commenterUser?.name ?? "Loading..."
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile Picture
            if let user = commenterUser {
                ProfileImageView(user: user, size: 32)
            } else {
                // Placeholder while loading
                Circle()
                    .fill(Color.bulkShareInfo.opacity(0.2))
                    .frame(width: 32, height: 32)
            }

            // Comment Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(commenterName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)

                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }

                Text(comment.text)
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextDark)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.bulkShareBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ClaimItemView(
        item: TripItem(
            name: "Popsicles (Box of 40)",
            quantityAvailable: 40,
            estimatedPrice: 0.50,
            category: .desserts,
            notes: "Keep frozen until event"
        ),
        existingClaims: [
            ItemClaim(
                tripId: "trip1",
                itemId: "item1",
                claimerUserId: "user1",
                quantityClaimed: 15,
                status: .accepted
            ),
            ItemClaim(
                tripId: "trip1",
                itemId: "item1",
                claimerUserId: "user2",
                quantityClaimed: 10,
                status: .pending
            )
        ],
        existingComments: ItemComment.sampleComments,
        tripShopperId: "shopper1",
        onClaim: { quantity in
            print("Claiming \(quantity) pieces")
        },
        onToggleCompletion: { claim in
            print("Toggling completion for claim \(claim.id)")
        },
        onAddComment: { text in
            print("Adding comment: \(text)")
        }
    )
}

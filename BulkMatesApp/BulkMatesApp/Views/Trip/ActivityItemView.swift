//
//  ActivityItemView.swift
//  BulkMatesApp
//
//  Individual activity item display
//

import SwiftUI

struct ActivityItemView: View {
    let activity: PlanActivity
    let currentUserId: String
    let onLike: () -> Void
    let onImageTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Activity type badge
            if let badge = typeBadge {
                HStack {
                    Text(badge.icon + " " + badge.text)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(badge.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(badge.backgroundColor)
                        .cornerRadius(12)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            // User info and content
            HStack(alignment: .top, spacing: 12) {
                // Profile picture
                ProfileImageFromURL(
                    imageURL: activity.userProfileImageURL,
                    userName: activity.userName,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 8) {
                    // User name and time
                    HStack {
                        Text(activity.userName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(timeAgoString(from: activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Message
                    if let message = activity.message {
                        Text(message)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Image (photo or receipt)
                    if let imageURL = activity.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: activity.type == .receipt ? 300 : 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        onImageTap()
                                    }
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                            Text("Failed to load image")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .overlay(
                                        ProgressView()
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    // Like button
                    HStack(spacing: 16) {
                        Button(action: onLike) {
                            HStack(spacing: 4) {
                                Image(systemName: activity.isLikedByUser(currentUserId) ? "heart.fill" : "heart")
                                    .foregroundColor(activity.isLikedByUser(currentUserId) ? .red : .gray)
                                if activity.likeCount > 0 {
                                    Text("\(activity.likeCount)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var typeBadge: (icon: String, text: String, color: Color, backgroundColor: Color)? {
        switch activity.type {
        case .comment:
            return nil  // No badge for regular comments
        case .photo:
            return ("📷", "Photo", .pink, Color.pink.opacity(0.1))
        case .receipt:
            return ("📄", "Receipt", .orange, Color.orange.opacity(0.1))
        case .location:
            return ("📍", "Location", .green, Color.green.opacity(0.1))
        case .systemActivity:
            return ("ℹ️", "Activity", .purple, Color.purple.opacity(0.1))
        }
    }

    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        // Comment activity
        ActivityItemView(
            activity: PlanActivity(
                tripId: "trip1",
                userId: "user1",
                userName: "John Smith",
                userProfileImageURL: nil,
                type: .comment,
                message: "Hey everyone! Just confirmed the Costco run for Saturday at 2pm. See you all there!",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            currentUserId: "user2",
            onLike: {},
            onImageTap: {}
        )

        // Photo activity
        ActivityItemView(
            activity: PlanActivity(
                tripId: "trip1",
                userId: "user2",
                userName: "Sarah Kumar",
                userProfileImageURL: nil,
                type: .photo,
                message: "Found the perfect birthday cake!",
                imageURL: "https://via.placeholder.com/400x300",
                timestamp: Date().addingTimeInterval(-7200)
            ),
            currentUserId: "user2",
            onLike: {},
            onImageTap: {}
        )

        // System activity
        ActivityItemView(
            activity: PlanActivity(
                tripId: "trip1",
                userId: "user3",
                userName: "Mike Johnson",
                userProfileImageURL: nil,
                type: .systemActivity,
                message: "claimed 2 packages of Kirkland Paper Towels",
                systemActivityType: .itemClaimed,
                timestamp: Date().addingTimeInterval(-10800)
            ),
            currentUserId: "user2",
            onLike: {},
            onImageTap: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

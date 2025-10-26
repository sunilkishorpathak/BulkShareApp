//
//  ProfileImageView.swift
//  BulkMatesApp
//
//  Created on BulkShare Project
//

import SwiftUI

/// Reusable profile image view that displays user's profile picture or initials
struct ProfileImageView: View {
    let user: User
    let size: CGFloat

    init(user: User, size: CGFloat = 40) {
        self.user = user
        self.size = size
    }

    var body: some View {
        Group {
            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_), .empty:
                        defaultImage
                    @unknown default:
                        defaultImage
                    }
                }
            } else {
                defaultImage
            }
        }
    }

    var defaultImage: some View {
        ZStack {
            Circle()
                .fill(Color.bulkSharePrimary.opacity(0.2))
                .frame(width: size, height: size)

            Text(user.initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.bulkSharePrimary)
        }
    }
}

/// Profile image view from URL string only (for cases where full User object isn't available)
struct ProfileImageFromURL: View {
    let imageURL: String?
    let userName: String
    let size: CGFloat

    init(imageURL: String?, userName: String, size: CGFloat = 40) {
        self.imageURL = imageURL
        self.userName = userName
        self.size = size
    }

    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_), .empty:
                        defaultImage
                    @unknown default:
                        defaultImage
                    }
                }
            } else {
                defaultImage
            }
        }
    }

    var defaultImage: some View {
        ZStack {
            Circle()
                .fill(Color.bulkSharePrimary.opacity(0.2))
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.bulkSharePrimary)
        }
    }

    private var initials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // With profile image URL
        ProfileImageFromURL(
            imageURL: "https://via.placeholder.com/150",
            userName: "John Smith",
            size: 80
        )

        // Without profile image (initials)
        ProfileImageFromURL(
            imageURL: nil,
            userName: "Sarah Kumar",
            size: 80
        )

        // Different sizes
        HStack(spacing: 16) {
            ProfileImageFromURL(imageURL: nil, userName: "Mike Johnson", size: 32)
            ProfileImageFromURL(imageURL: nil, userName: "Lisa Chen", size: 48)
            ProfileImageFromURL(imageURL: nil, userName: "Tom Wilson", size: 64)
        }
    }
    .padding()
}

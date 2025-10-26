//
//  FullScreenImageView.swift
//  BulkMatesApp
//
//  Full-screen view for activity photos and receipts with zoom
//

import SwiftUI

struct FullScreenImageView: View {
    let activity: PlanActivity
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if let imageURL = activity.imageURL {
                        ShareLink(item: URL(string: imageURL)!) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()

                Spacer()

                // Image
                if let imageURL = activity.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale *= delta
                                        }
                                        .onEnded { value in
                                            // Reset if zoomed out too much
                                            if scale < 1 {
                                                withAnimation {
                                                    scale = 1
                                                    lastScale = 1
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }

                                            // Limit max zoom
                                            if scale > 4 {
                                                withAnimation {
                                                    scale = 4
                                                    lastScale = 4
                                                }
                                            }
                                        }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1 {
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                        }
                                        .onEnded { value in
                                            lastOffset = offset
                                        }
                                )
                                .gesture(
                                    TapGesture(count: 2)
                                        .onEnded {
                                            withAnimation(.spring()) {
                                                if scale > 1 {
                                                    scale = 1
                                                    lastScale = 1
                                                    offset = .zero
                                                    lastOffset = .zero
                                                } else {
                                                    scale = 2
                                                    lastScale = 2
                                                }
                                            }
                                        }
                                )
                        case .failure(_):
                            VStack(spacing: 16) {
                                Image(systemName: "photo")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Failed to load image")
                                    .foregroundColor(.white)
                            }
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Spacer()

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProfileImageFromURL(
                            imageURL: activity.userProfileImageURL,
                            userName: activity.userName,
                            size: 32
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.userName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Text(activity.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()
                    }

                    if let message = activity.message {
                        Text(message)
                            .font(.body)
                            .foregroundColor(.white)
                    }

                    // Zoom hint
                    if scale == 1 {
                        Text("Double tap to zoom • Pinch to zoom • Drag to pan")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 4)
                    } else {
                        Text("Zoom: \(Int(scale * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }
    }
}

#Preview {
    FullScreenImageView(
        activity: PlanActivity(
            tripId: "trip1",
            userId: "user1",
            userName: "John Smith",
            userProfileImageURL: nil,
            type: .photo,
            message: "Found the perfect cake!",
            imageURL: "https://via.placeholder.com/800x600",
            timestamp: Date()
        ),
        isPresented: .constant(true)
    )
}

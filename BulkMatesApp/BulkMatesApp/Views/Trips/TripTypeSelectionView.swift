//
//  TripTypeSelectionView.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI

struct TripTypeSelectionView: View {
    let group: Group
    let onTripTypeSelected: (TripType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTripType: TripType? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(spacing: 12) {
                            Text("What are you planning?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.bulkShareTextDark)

                            Text("Choose the type of plan you want to create for \(group.name)")
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextMedium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        // Trip Type Options
                        VStack(spacing: 16) {
                            ForEach(TripType.allCases, id: \.self) { tripType in
                                TripTypeCard(
                                    tripType: tripType,
                                    isSelected: selectedTripType == tripType,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTripType = tripType
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Continue Button
                        if let selected = selectedTripType {
                            Button(action: {
                                onTripTypeSelected(selected)
                            }) {
                                HStack {
                                    Text("Continue")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.bulkSharePrimary)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Create New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
        }
    }
}

// MARK: - Trip Type Card
struct TripTypeCard: View {
    let tripType: TripType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.bulkSharePrimary.opacity(0.15) : Color.bulkShareBackground)
                        .frame(width: 60, height: 60)

                    Text(tripType.icon)
                        .font(.system(size: 30))
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(tripType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)

                    Text(tripType.description)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.bulkSharePrimary : Color.bulkShareTextLight, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.bulkSharePrimary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.bulkSharePrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.bulkSharePrimary.opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 6 : 3)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    TripTypeSelectionView(
        group: Group.sampleGroups[0],
        onTripTypeSelected: { tripType in
            print("Selected: \(tripType.displayName)")
        }
    )
}

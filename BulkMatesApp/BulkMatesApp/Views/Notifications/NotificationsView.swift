//
//  NotificationsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedTrip: Trip?
    @State private var isLoadingTrip = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                if isLoadingTrip {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading plan details...")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notificationManager.notifications.isEmpty {
                    EmptyNotificationsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notificationManager.notifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onAccept: { handleNotificationResponse(notification, .accepted) },
                                    onReject: { handleNotificationResponse(notification, .rejected) },
                                    onMarkAsRead: { markAsRead(notification) },
                                    onTap: { handleNotificationTap(notification) }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if notificationManager.unreadCount > 0 {
                        Button("Mark All Read") {
                            markAllAsRead()
                        }
                        .foregroundColor(.bulkSharePrimary)
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                startListeningForNotifications()
            }
            .sheet(item: $selectedTrip) { trip in
                NavigationView {
                    TripDetailView(trip: trip)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedTrip = nil
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func startListeningForNotifications() {
        guard let currentUser = FirebaseManager.shared.currentUser else { 
            print("❌ No current user found for notifications")
            return 
        }
        print("🔔 Starting notification listener for user: \(currentUser.id) (\(currentUser.email))")
        notificationManager.startListening(for: currentUser.id)
    }
    
    private func handleNotificationResponse(_ notification: Notification, _ response: NotificationStatus) {
        guard notification.type == .groupInvitation else { return }
        
        isLoading = true
        
        Task {
            do {
                try await notificationManager.respondToGroupInvitation(
                    notificationId: notification.id,
                    response: response,
                    groupId: notification.relatedId,
                    userId: notification.recipientUserId
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    let action = response == .accepted ? "accepted" : "rejected"
                    self.showAlert(
                        title: "Response Sent",
                        message: "You have \(action) the group invitation."
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Error",
                        message: "Failed to respond: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func markAsRead(_ notification: Notification) {
        Task {
            try await notificationManager.markAsRead(notification.id)
        }
    }
    
    private func markAllAsRead() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        Task {
            try await notificationManager.markAllAsRead(for: currentUser.id)
        }
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        // Mark notification as read
        markAsRead(notification)
        
        // If it's a trip notification, load and show trip details
        if notification.type == .tripInvitation || notification.type == .tripUpdate {
            loadTripDetails(tripId: notification.relatedId)
        }
    }
    
    private func loadTripDetails(tripId: String) {
        isLoadingTrip = true
        print("🔍 Loading trip details for tripId: \(tripId)")
        
        Task {
            do {
                let trip = try await FirebaseManager.shared.getTrip(tripId: tripId)
                print("✅ Successfully loaded trip: \(trip.id) - \(trip.store.displayName)")
                DispatchQueue.main.async {
                    self.isLoadingTrip = false
                    self.selectedTrip = trip
                    print("🎯 Set selectedTrip, should trigger sheet")
                }
            } catch {
                print("❌ Error loading trip: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingTrip = false
                    self.showAlert(
                        title: "Error",
                        message: "Could not load plan details: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct NotificationCard: View {
    let notification: Notification
    let onAccept: () -> Void
    let onReject: () -> Void
    let onMarkAsRead: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            // Only trigger tap for trip notifications
            if notification.type == .tripInvitation || notification.type == .tripUpdate {
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: notification.type.icon)
                        .foregroundColor(Color(notification.type.color))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(notification.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.bulkShareTextDark)
                        
                        Text(notification.message)
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(timeAgoString(from: notification.createdAt))
                            .font(.caption)
                            .foregroundColor(.bulkShareTextLight)
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.bulkSharePrimary)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                // Status or Action Buttons
                if notification.status == .pending && notification.type == .groupInvitation {
                    HStack(spacing: 12) {
                        Button(action: onReject) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("Decline")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button(action: onAccept) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Accept")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.bulkSharePrimary)
                            .cornerRadius(8)
                        }
                    }
                } else {
                    HStack {
                        Text("Status: \(notification.status.displayText)")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Button("Mark as read") {
                                onMarkAsRead()
                            }
                            .font(.caption)
                            .foregroundColor(.bulkSharePrimary)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(notification.isRead ? Color.white : Color.bulkSharePrimary.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.bulkShareTextLight)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextMedium)
            
            Text("You're all caught up! New notifications will appear here.")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NotificationsView()
}
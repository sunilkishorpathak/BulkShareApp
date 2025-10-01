//
//  MainTabView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        TabView {
            // My Groups Tab
            MyGroupsView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("My Groups")
                }
            
            // Browse Groups Tab
            BrowseGroupsView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Browse")
                }
            
            // My Trips Tab
            MyTripsView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("My Trips")
                }
            
            // Notifications Tab
            NotificationsView()
                .tabItem {
                    Image(systemName: notificationManager.unreadCount > 0 ? "bell.badge.fill" : "bell")
                    Text("Notifications")
                }
            
            // Profile Tab
            UserProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.bulkSharePrimary)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startListeningForNotifications()
        }
    }
    
    private func startListeningForNotifications() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        notificationManager.startListening(for: currentUser.id)
    }
}

#Preview {
    MainTabView()
}

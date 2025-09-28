//
//  MainTabView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct MainTabView: View {
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
            
            // Profile Tab
            UserProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.bulkSharePrimary)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MainTabView()
}

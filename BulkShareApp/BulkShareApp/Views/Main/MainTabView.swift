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
        }
        .accentColor(.bulkSharePrimary)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MainTabView()
}

//
//  MainTabView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


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
            NavigationView {
                VStack {
                    Text("🏠 My Groups")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkSharePrimary)
                    
                    Text("Coming Soon!")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                .navigationTitle("My Groups")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("My Groups")
            }
            
            // Browse Tab
            NavigationView {
                VStack {
                    Text("🔍 Browse Groups")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkSharePrimary)
                    
                    Text("Coming Soon!")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                .navigationTitle("Browse")
            }
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
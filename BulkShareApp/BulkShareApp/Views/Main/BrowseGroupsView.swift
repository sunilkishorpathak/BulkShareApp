//
//  BrowseGroupsView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  BrowseGroupsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct BrowseGroupsView: View {
    @State private var searchText = ""
    @State private var availableGroups: [Group] = Group.sampleGroups
    @State private var showingJoinAlert = false
    @State private var selectedGroup: Group?
    
    var filteredGroups: [Group] {
        if searchText.isEmpty {
            return availableGroups
        } else {
            return availableGroups.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText) ||
                group.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bulkShareBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding()
                    
                    // Groups List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if filteredGroups.isEmpty {
                                EmptySearchView(searchText: searchText)
                            } else {
                                ForEach(filteredGroups) { group in
                                    BrowseGroupCard(group: group) {
                                        selectedGroup = group
                                        showingJoinAlert = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Browse Groups")
            .navigationBarTitleDisplayMode(.large)
            .alert("Join Group", isPresented: $showingJoinAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Request to Join") {
                    if let group = selectedGroup {
                        handleJoinRequest(group: group)
                    }
                }
            } message: {
                if let group = selectedGroup {
                    Text("Would you like to request to join \"\(group.name)\"?")
                }
            }
        }
    }
    
    private func handleJoinRequest(group: Group) {
        // Simulate join request
        // In real app, this would send a request to group admin
        print("Requesting to join group: \(group.name)")
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.bulkShareTextMedium)
            
            TextField("Search groups...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.bulkShareTextMedium)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct BrowseGroupCard: View {
    let group: Group
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(group.icon)
                    .font(.title)
                    .frame(width: 50, height: 50)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("\(group.memberCount) members")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
            }
            
            // Description
            Text(group.description)
                .font(.subheadline)
                .foregroundColor(.bulkShareTextMedium)
                .lineLimit(3)
            
            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Active group", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.bulkShareSuccess)
                    
                    Text("Created \(group.createdAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                
                Spacer()
                
                Button(action: onJoin) {
                    Text("Request to Join")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.bulkSharePrimary)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.bulkShareTextLight)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Groups Found" : "No Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.bulkShareTextDark)
                
                Text(searchText.isEmpty 
                     ? "There are no groups available to join right now"
                     : "Try searching for different keywords")
                    .font(.subheadline)
                    .foregroundColor(.bulkShareTextMedium)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    BrowseGroupsView()
}
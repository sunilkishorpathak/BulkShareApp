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
    @State private var availableGroups: [Group] = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
                    if isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                                .scaleEffect(1.5)
                            
                            Text("Loading available groups...")
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextMedium)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if filteredGroups.isEmpty {
                                    EmptySearchView(searchText: searchText)
                                } else {
                                    ForEach(filteredGroups) { group in
                                        BrowseGroupCard(group: group)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .refreshable {
                            await loadAllGroups()
                        }
                    }
                }
            }
            .navigationTitle("Browse Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onAppear {
                Task { await loadAllGroups() }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @MainActor
    private func loadAllGroups() async {
        isLoading = true
        
        do {
            let groups = try await FirebaseManager.shared.getAllGroups()
            self.availableGroups = groups
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = "Failed to load groups: \(error.localizedDescription)"
            self.showingError = true
        }
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

                VStack(alignment: .trailing, spacing: 4) {
                    Label("Invite code required", systemImage: "key.fill")
                        .font(.caption)
                        .foregroundColor(.bulkSharePrimary)

                    Text("Ask admin for code")
                        .font(.caption2)
                        .foregroundColor(.bulkShareTextLight)
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
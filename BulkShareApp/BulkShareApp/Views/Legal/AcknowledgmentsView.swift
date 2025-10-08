//
//  AcknowledgmentsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct AcknowledgmentsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Acknowledgments")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("We extend our heartfelt gratitude to everyone who contributed to making BulkMates a reality.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        LegalSectionView(title: "Development Team") {
                            Text("BulkMates was brought to life by:")
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sunil Kishor Pathak")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Lead Developer - Architected and developed the complete BulkMates application, implementing all core features and functionality.")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Akshat Pathak")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Co-Developer - Provided invaluable assistance in shaping features, design decisions, and development process. Your collaboration and insights have been essential to the project's success.")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        LegalSectionView(title: "Beta Testers & Contributors") {
                            Text("Special thanks to our dedicated beta testers and contributors who helped shape BulkMates:")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach([
                                    "Deep Arora",
                                    "Rajnikanth Sharma", 
                                    "Dharmendra Kumar",
                                    "Bhanu Sisodia"
                                ], id: \.self) { name in
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.bulkSharePrimary)
                                            .font(.caption)
                                        
                                        Text(name)
                                            .font(.body)
                                            .foregroundColor(.bulkShareTextDark)
                                    }
                                }
                            }
                            .padding(.top, 8)
                            
                            Text("Thank you for your valuable testing, feedback, and feature suggestions that helped us refine and improve the app experience.")
                                .font(.body)
                                .foregroundColor(.bulkShareTextMedium)
                                .padding(.top, 8)
                        }
                        
                        LegalSectionView(title: "Technology Partners") {
                            Text("BulkMates is built using modern technologies including:")
                            LegalBulletPoint("SwiftUI for iOS development")
                            LegalBulletPoint("Firebase for backend services")
                            LegalBulletPoint("Apple's development ecosystem")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Acknowledgments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AcknowledgmentsView()
}
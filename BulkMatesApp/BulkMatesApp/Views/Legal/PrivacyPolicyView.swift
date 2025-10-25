//
//  PrivacyPolicyView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Last updated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        LegalSectionView(title: "1. Information We Collect") {
                            Text("We collect information you provide directly to us, such as when you create an account, join groups, create shopping plans, or contact us for support. This may include:")
                            LegalBulletPoint("Name and email address")
                            LegalBulletPoint("Group memberships and plan participation")
                            LegalBulletPoint("Shopping preferences and history")
                        }
                        
                        LegalSectionView(title: "2. How We Use Your Information") {
                            Text("We use the information we collect to:")
                            LegalBulletPoint("Provide, maintain, and improve our services")
                            LegalBulletPoint("Coordinate bulk shopping plans and item sharing")
                            LegalBulletPoint("Send you notifications about plans and group activities")
                            LegalBulletPoint("Respond to your comments and questions")
                            LegalBulletPoint("Prevent fraud and enhance security")
                        }
                        
                        LegalSectionView(title: "3. Information Sharing") {
                            Text("We do not sell, trade, or otherwise transfer your personal information to third parties except:")
                            LegalBulletPoint("With your consent")
                            LegalBulletPoint("To group members for coordination purposes")
                            LegalBulletPoint("To comply with legal obligations")
                            LegalBulletPoint("To protect our rights and safety")
                        }
                        
                        LegalSectionView(title: "4. Data Security") {
                            Text("We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.")
                        }
                        
                        LegalSectionView(title: "5. Your Rights") {
                            Text("You have the right to:")
                            LegalBulletPoint("Access and update your personal information")
                            LegalBulletPoint("Delete your account and associated data")
                            LegalBulletPoint("Opt out of certain communications")
                            LegalBulletPoint("Request a copy of your data")
                        }
                        
                        LegalSectionView(title: "6. Contact Us") {
                            Text("If you have any questions about this Privacy Policy, please contact us at:")
                            Text("Email: privacy@bulkmates.app")
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
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
    PrivacyPolicyView()
}
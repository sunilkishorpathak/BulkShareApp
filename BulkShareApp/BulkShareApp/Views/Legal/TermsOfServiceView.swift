//
//  TermsOfServiceView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Last updated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        LegalSectionView(title: "1. Acceptance of Terms") {
                            Text("By downloading, installing, or using the BulkShare app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.")
                        }
                        
                        LegalSectionView(title: "2. Description of Service") {
                            Text("BulkShare is a platform that helps users coordinate bulk shopping purchases within groups. Our service allows you to:")
                            LegalBulletPoint("Create and join shopping groups")
                            LegalBulletPoint("Organize bulk shopping trips")
                            LegalBulletPoint("Share items and coordinate payments")
                            LegalBulletPoint("Track expenses and settlements")
                        }
                        
                        LegalSectionView(title: "3. User Responsibilities") {
                            Text("You agree to:")
                            LegalBulletPoint("Provide accurate and truthful information")
                            LegalBulletPoint("Use the service only for lawful purposes")
                            LegalBulletPoint("Respect other users and their property")
                            LegalBulletPoint("Honor payment commitments made through the app")
                            LegalBulletPoint("Not misuse or abuse the service")
                        }
                        
                        LegalSectionView(title: "4. Payment and Transactions") {
                            Text("BulkShare facilitates coordination of payments but does not process payments directly. Users are responsible for:")
                            LegalBulletPoint("Completing payments as agreed")
                            LegalBulletPoint("Resolving payment disputes directly with other users")
                            LegalBulletPoint("Ensuring payment method information is accurate")
                        }
                        
                        LegalSectionView(title: "5. Privacy and Data") {
                            Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.")
                        }
                        
                        LegalSectionView(title: "6. Limitation of Liability") {
                            Text("BulkShare is provided 'as is' without warranties. We are not liable for:")
                            LegalBulletPoint("Disputes between users")
                            LegalBulletPoint("Quality or safety of purchased items")
                            LegalBulletPoint("Payment defaults or fraud")
                            LegalBulletPoint("Service interruptions or data loss")
                        }
                        
                        LegalSectionView(title: "7. Termination") {
                            Text("You may terminate your account at any time. We reserve the right to suspend or terminate accounts that violate these terms.")
                        }
                        
                        LegalSectionView(title: "8. Changes to Terms") {
                            Text("We may modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.")
                        }
                        
                        LegalSectionView(title: "9. Contact Information") {
                            Text("For questions about these Terms of Service, contact us at:")
                            Text("Email: legal@bulkshare.app")
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
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
    TermsOfServiceView()
}
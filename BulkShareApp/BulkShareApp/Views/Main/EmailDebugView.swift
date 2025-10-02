//
//  EmailDebugView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct EmailDebugView: View {
    @State private var emailLogs: [EmailLog] = []
    @State private var isMonitoring = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                VStack(spacing: 8) {
                    Text("📧 Email Debug Console")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text("Monitor email notifications in development")
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                .padding()
                
                // Email Logs
                if emailLogs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 60))
                            .foregroundColor(.bulkShareTextLight)
                        
                        Text("No emails sent yet")
                            .font(.headline)
                            .foregroundColor(.bulkShareTextMedium)
                        
                        Text("Sign up for an account or create a group to see email notifications here")
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextLight)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(emailLogs) { log in
                                EmailLogCard(log: log)
                            }
                        }
                        .padding()
                    }
                }
                
                // Clear Button
                if !emailLogs.isEmpty {
                    Button("Clear Logs") {
                        emailLogs.removeAll()
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
                }
            }
            .navigationTitle("Email Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            startMonitoring()
        }
    }
    
    private func startMonitoring() {
        // In a real implementation, this would listen to email service notifications
        // For now, we'll simulate some email logs
        emailLogs = [
            EmailLog(
                type: .welcome,
                recipient: "user@example.com",
                subject: "Welcome to BulkShare! 🍃",
                timestamp: Date().addingTimeInterval(-300),
                status: .sent
            ),
            EmailLog(
                type: .groupInvitation,
                recipient: "friend@example.com",
                subject: "John invited you to join \"Family Group\" on BulkShare",
                timestamp: Date().addingTimeInterval(-120),
                status: .sent
            )
        ]
    }
}

struct EmailLogCard: View {
    let log: EmailLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(log.type.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text(log.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextLight)
                }
                
                Spacer()
                
                StatusBadge(status: log.status)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("To: \(log.recipient)")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
                
                Text("Subject: \(log.subject)")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: EmailStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(8)
    }
}

// MARK: - Supporting Types

struct EmailLog: Identifiable {
    let id = UUID()
    let type: EmailType
    let recipient: String
    let subject: String
    let timestamp: Date
    let status: EmailStatus
}

enum EmailType {
    case welcome
    case groupInvitation
    case tripNotification
    case passwordReset
    
    var displayName: String {
        switch self {
        case .welcome: return "Welcome"
        case .groupInvitation: return "Group Invitation"
        case .tripNotification: return "Trip Notification"
        case .passwordReset: return "Password Reset"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome: return "👋"
        case .groupInvitation: return "👥"
        case .tripNotification: return "🛒"
        case .passwordReset: return "🔐"
        }
    }
}

enum EmailStatus {
    case sent
    case failed
    case pending
    
    var displayName: String {
        switch self {
        case .sent: return "Sent"
        case .failed: return "Failed"
        case .pending: return "Pending"
        }
    }
    
    var color: Color {
        switch self {
        case .sent: return .green
        case .failed: return .red
        case .pending: return .orange
        }
    }
}

#Preview {
    EmailDebugView()
}
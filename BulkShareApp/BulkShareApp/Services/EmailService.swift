//
//  EmailService.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation
import MessageUI

class EmailService: NSObject, ObservableObject {
    static let shared = EmailService()
    
    @Published var isEmailAvailable = MFMailComposeViewController.canSendMail()
    
    override init() {
        super.init()
        checkEmailAvailability()
    }
    
    private func checkEmailAvailability() {
        isEmailAvailable = MFMailComposeViewController.canSendMail()
    }
    
    // MARK: - Group Invitation Emails
    
    func sendGroupInvitations(
        groupName: String,
        inviterName: String,
        memberEmails: [String],
        groupId: String
    ) async -> Result<Void, EmailError> {
        
        guard !memberEmails.isEmpty else {
            return .failure(.noRecipients)
        }
        
        // For now, we'll use a web-based email service
        // In production, you'd use services like SendGrid, Mailgun, or Firebase Functions
        
        do {
            for email in memberEmails {
                try await sendGroupInvitationEmail(
                    to: email,
                    groupName: groupName,
                    inviterName: inviterName,
                    groupId: groupId
                )
            }
            return .success(())
        } catch {
            return .failure(.sendFailed(error.localizedDescription))
        }
    }
    
    private func sendGroupInvitationEmail(
        to email: String,
        groupName: String,
        inviterName: String,
        groupId: String
    ) async throws {
        
        // Create email content
        let subject = "\(inviterName) invited you to join \"\(groupName)\" on BulkShare"
        let htmlBody = createGroupInvitationHTML(
            groupName: groupName,
            inviterName: inviterName,
            recipientEmail: email,
            groupId: groupId
        )
        
        // For development/testing, we'll simulate email sending
        // In production, replace this with actual email service
        print("📧 SIMULATED EMAIL SENT:")
        print("To: \(email)")
        print("Subject: \(subject)")
        print("Body: \(htmlBody)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // TODO: Implement actual email sending using:
        // - Firebase Functions with SendGrid/Mailgun
        // - AWS SES
        // - Third-party email service API
    }
    
    // MARK: - Welcome Email
    
    func sendWelcomeEmail(to email: String, userName: String) async -> Result<Void, EmailError> {
        do {
            let subject = "Welcome to BulkShare! 🍃"
            let htmlBody = createWelcomeEmailHTML(userName: userName)
            
            // Simulate sending welcome email
            print("📧 WELCOME EMAIL SENT:")
            print("To: \(email)")
            print("Subject: \(subject)")
            print("Body: \(htmlBody)")
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            return .success(())
        } catch {
            return .failure(.sendFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Trip Notification Emails
    
    func sendTripNotification(
        to emails: [String],
        tripDetails: TripEmailDetails
    ) async -> Result<Void, EmailError> {
        
        do {
            for email in emails {
                try await sendTripNotificationEmail(to: email, tripDetails: tripDetails)
            }
            return .success(())
        } catch {
            return .failure(.sendFailed(error.localizedDescription))
        }
    }
    
    private func sendTripNotificationEmail(
        to email: String,
        tripDetails: TripEmailDetails
    ) async throws {
        
        let subject = "New BulkShare trip: \(tripDetails.storeName) - \(tripDetails.date)"
        let htmlBody = createTripNotificationHTML(tripDetails: tripDetails)
        
        print("📧 TRIP NOTIFICATION SENT:")
        print("To: \(email)")
        print("Subject: \(subject)")
        print("Body: \(htmlBody)")
        
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    // MARK: - HTML Email Templates
    
    private func createGroupInvitationHTML(
        groupName: String,
        inviterName: String,
        recipientEmail: String,
        groupId: String
    ) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>BulkShare Group Invitation</title>
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
            
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #4CAF50; font-size: 28px; margin-bottom: 10px;">🍃 BulkShare</h1>
                <p style="color: #666; font-size: 16px;">Share Smarter, Waste Less</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 25px; border-radius: 12px; margin-bottom: 25px;">
                <h2 style="color: #333; margin-top: 0;">You're Invited! 🎉</h2>
                <p style="font-size: 16px; margin-bottom: 15px;">
                    <strong>\(inviterName)</strong> has invited you to join the <strong>"\(groupName)"</strong> group on BulkShare.
                </p>
                <p style="color: #666; margin-bottom: 20px;">
                    BulkShare helps groups coordinate bulk shopping trips to save money and reduce waste. 
                    Join your group to participate in upcoming trips and split the costs!
                </p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="bulkshare://join-group/\(groupId)" style="background: linear-gradient(45deg, #4CAF50, #45a049); color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: 600; display: inline-block;">
                    Join Group
                </a>
            </div>
            
            <div style="background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 25px 0;">
                <h3 style="color: #2e7d32; margin-top: 0;">What is BulkShare?</h3>
                <ul style="color: #2e7d32; padding-left: 20px;">
                    <li>Coordinate bulk shopping trips with friends and neighbors</li>
                    <li>Split costs and save money on bulk purchases</li>
                    <li>Reduce waste by sharing large quantities</li>
                    <li>Build stronger community connections</li>
                </ul>
            </div>
            
            <div style="text-align: center; color: #666; font-size: 14px; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee;">
                <p>Don't have the BulkShare app yet?</p>
                <p>
                    <a href="https://apps.apple.com/app/bulkshare" style="color: #4CAF50; text-decoration: none;">Download for iOS</a> • 
                    <a href="https://play.google.com/store/apps/details?id=bulkshare" style="color: #4CAF50; text-decoration: none;">Download for Android</a>
                </p>
                <p style="margin-top: 20px; font-size: 12px;">
                    This email was sent to \(recipientEmail). If you don't want to receive these emails, you can unsubscribe.
                </p>
            </div>
            
        </body>
        </html>
        """
    }
    
    private func createWelcomeEmailHTML(userName: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Welcome to BulkShare</title>
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
            
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #4CAF50; font-size: 32px; margin-bottom: 10px;">🍃 Welcome to BulkShare!</h1>
                <p style="color: #666; font-size: 18px;">Share Smarter, Waste Less</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 25px; border-radius: 12px; margin-bottom: 25px;">
                <h2 style="color: #333; margin-top: 0;">Hi \(userName)! 👋</h2>
                <p style="font-size: 16px; margin-bottom: 15px;">
                    Thank you for joining BulkShare! You're now part of a community that's making shopping smarter and more sustainable.
                </p>
            </div>
            
            <div style="background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 25px 0;">
                <h3 style="color: #2e7d32; margin-top: 0;">Getting Started:</h3>
                <ol style="color: #2e7d32; padding-left: 20px;">
                    <li>Create or join a group with friends, family, or neighbors</li>
                    <li>Plan bulk shopping trips to stores like Costco or Sam's Club</li>
                    <li>Split costs and share the savings</li>
                    <li>Reduce waste by sharing bulk quantities</li>
                </ol>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="bulkshare://open" style="background: linear-gradient(45deg, #4CAF50, #45a049); color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: 600; display: inline-block;">
                    Open BulkShare
                </a>
            </div>
            
            <div style="text-align: center; color: #666; font-size: 14px; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee;">
                <p>Need help? Contact us at support@bulkshare.app</p>
                <p style="margin-top: 20px; font-size: 12px;">
                    Happy bulk sharing! 🛒✨
                </p>
            </div>
            
        </body>
        </html>
        """
    }
    
    private func createTripNotificationHTML(tripDetails: TripEmailDetails) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>New BulkShare Trip</title>
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
            
            <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #4CAF50; font-size: 28px; margin-bottom: 10px;">🍃 BulkShare</h1>
                <p style="color: #666; font-size: 16px;">New Trip Available!</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 25px; border-radius: 12px; margin-bottom: 25px;">
                <h2 style="color: #333; margin-top: 0;">\(tripDetails.storeName) Trip 🛒</h2>
                <p style="font-size: 16px; margin-bottom: 15px;">
                    <strong>\(tripDetails.organizerName)</strong> is organizing a trip to <strong>\(tripDetails.storeName)</strong>
                </p>
                <p style="color: #666; margin-bottom: 10px;"><strong>When:</strong> \(tripDetails.date)</p>
                <p style="color: #666; margin-bottom: 10px;"><strong>Items:</strong> \(tripDetails.itemCount) items</p>
                <p style="color: #666;"><strong>Estimated Cost:</strong> $\(tripDetails.estimatedCost)</p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="bulkshare://trip/\(tripDetails.tripId)" style="background: linear-gradient(45deg, #4CAF50, #45a049); color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: 600; display: inline-block;">
                    View Trip Details
                </a>
            </div>
            
        </body>
        </html>
        """
    }
}

// MARK: - Supporting Types

enum EmailError: LocalizedError {
    case noRecipients
    case sendFailed(String)
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .noRecipients:
            return "No email recipients provided"
        case .sendFailed(let reason):
            return "Failed to send email: \(reason)"
        case .notAvailable:
            return "Email service not available"
        }
    }
}

struct TripEmailDetails {
    let tripId: String
    let storeName: String
    let organizerName: String
    let date: String
    let itemCount: Int
    let estimatedCost: String
}
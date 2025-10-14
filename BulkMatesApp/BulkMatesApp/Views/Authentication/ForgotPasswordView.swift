//
//  ForgotPasswordView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  ForgotPasswordView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var selectedMethod: ResetMethod = .email
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingPhoneVerification: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    enum ResetMethod: String, CaseIterable {
        case email = "Email"
        case phone = "Phone"
        
        var icon: String {
            switch self {
            case .email: return "envelope.fill"
            case .phone: return "phone.fill"
            }
        }
        
        var description: String {
            switch self {
            case .email: return "We'll email you a reset link"
            case .phone: return "We'll send a code to your phone"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.bulkSharePrimary,
                    Color.bulkShareSecondary
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating Background Elements
            FloatingElementsView()
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 80)
                    
                    // Logo and Branding
                    VStack(spacing: 20) {
                        // Logo
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: selectedMethod.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        // Title
                        Text("Reset Password")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(selectedMethod.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Reset Form
                    AuthFormCard {
                        VStack(spacing: 24) {
                            // Method Selection
                            VStack(spacing: 12) {
                                Text("Choose reset method")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextDark)
                                
                                HStack(spacing: 0) {
                                    ForEach(ResetMethod.allCases, id: \.self) { method in
                                        Button(action: { selectedMethod = method }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: method.icon)
                                                Text(method.rawValue)
                                                    .fontWeight(.medium)
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(selectedMethod == method ? .white : .bulkShareTextMedium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedMethod == method ? 
                                                Color.bulkSharePrimary : Color.clear
                                            )
                                        }
                                    }
                                }
                                .background(Color.bulkShareBackground)
                                .cornerRadius(8)
                            }
                            
                            // Instructions
                            VStack(spacing: 8) {
                                Text(selectedMethod == .email ? 
                                    "Enter your email address and we'll send you a link to reset your password." :
                                    "We'll send a verification code to your phone number to reset your password."
                                )
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextMedium)
                                .multilineTextAlignment(.center)
                            }
                            
                            if selectedMethod == .email {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email Address")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.bulkShareTextMedium)
                                    
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(BulkShareTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                }
                                
                                // Send Reset Link Button
                                Button(action: handlePasswordReset) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Send Reset Link")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.bulkSharePrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isLoading || email.isEmpty || !isValidEmail(email))
                                .opacity(email.isEmpty || !isValidEmail(email) ? 0.6 : 1.0)
                            } else {
                                // Phone Verification Button
                                Button(action: { showingPhoneVerification = true }) {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                        Text("Verify Phone Number")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.bulkSharePrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Back to Login Link
                            HStack {
                                Text("Remember your password?")
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                Button("Login") {
                                    dismiss()
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkSharePrimary)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                if alertTitle == "Reset Link Sent" || alertTitle == "Password Reset Sent" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingPhoneVerification) {
            PhoneVerificationView(
                purpose: .passwordReset,
                onSuccess: {
                    showingPhoneVerification = false
                    showAlert(
                        title: "Password Reset Sent",
                        message: "A password reset link has been sent to your email address."
                    )
                },
                onCancel: {
                    showingPhoneVerification = false
                }
            )
        }
    }
    
    private func handlePasswordReset() {
        guard isValidEmail(email) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
            return
        }
        
        isLoading = true
        
        Task {
            let result = await FirebaseManager.shared.sendPasswordReset(email: email)
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.showAlert(
                        title: "Reset Link Sent",
                        message: "If an account with this email exists, you'll receive a password reset link shortly."
                    )
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    NavigationView {
        ForgotPasswordView()
    }
}

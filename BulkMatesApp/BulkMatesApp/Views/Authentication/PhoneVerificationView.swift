//
//  PhoneVerificationView.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI

struct PhoneVerificationView: View {
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID = ""
    @State private var isLoading = false
    @State private var showingVerificationInput = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var attemptsRemaining = 3
    @State private var resetTime: Date?
    
    let purpose: VerificationPurpose
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    enum VerificationPurpose {
        case passwordReset
        case phoneLogin
        case changePhoneNumber
        
        var title: String {
            switch self {
            case .passwordReset: return "Reset Password"
            case .phoneLogin: return "Phone Login"
            case .changePhoneNumber: return "Change Phone Number"
            }
        }
        
        var subtitle: String {
            switch self {
            case .passwordReset: return "Enter your phone number to reset your password"
            case .phoneLogin: return "Enter your phone number to sign in"
            case .changePhoneNumber: return "Enter your new phone number"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.bulkSharePrimary)
                        
                        Text(purpose.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.bulkShareTextDark)
                        
                        Text(purpose.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.bulkShareTextMedium)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    if !showingVerificationInput {
                        // Phone Number Input
                        phoneNumberInputSection
                    } else {
                        // Verification Code Input
                        verificationCodeInputSection
                    }
                    
                    // Rate Limit Info
                    if attemptsRemaining < 3 {
                        rateLimitInfoSection
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isLoading)
        }
    }
    
    private var phoneNumberInputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)
                
                HStack {
                    // Country Code
                    Text("🇺🇸 +1")
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(Color.bulkShareBackground)
                        .cornerRadius(8)
                    
                    // Phone Number Input
                    TextField("(555) 123-4567", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.bulkShareBorder, lineWidth: 1)
                        )
                        .onChange(of: phoneNumber) { _ in
                            formatPhoneNumber()
                        }
                }
            }
            
            Button(action: sendVerificationCode) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isLoading ? "Sending..." : "Send Verification Code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    phoneNumber.isEmpty || isLoading ? 
                    Color.bulkShareTextLight : Color.bulkSharePrimary
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(phoneNumber.isEmpty || isLoading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    private var verificationCodeInputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.bulkShareTextDark)
                
                Text("Enter the 6-digit code sent to \(phoneNumber)")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
                
                TextField("000000", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.bulkShareBorder, lineWidth: 1)
                    )
                    .onChange(of: verificationCode) { _ in
                        if verificationCode.count > 6 {
                            verificationCode = String(verificationCode.prefix(6))
                        }
                        if verificationCode.count == 6 {
                            verifyCode()
                        }
                    }
            }
            
            Button(action: verifyCode) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isLoading ? "Verifying..." : "Verify Code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    verificationCode.count != 6 || isLoading ? 
                    Color.bulkShareTextLight : Color.bulkSharePrimary
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(verificationCode.count != 6 || isLoading)
            
            Button("Resend Code") {
                sendVerificationCode()
            }
            .font(.subheadline)
            .foregroundColor(.bulkSharePrimary)
            
            Button("Change Phone Number") {
                showingVerificationInput = false
                verificationCode = ""
                verificationID = ""
            }
            .font(.caption)
            .foregroundColor(.bulkShareTextMedium)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    private var rateLimitInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.bulkShareWarning)
                Text("\(attemptsRemaining) attempts remaining today")
                    .font(.caption)
                    .foregroundColor(.bulkShareTextMedium)
            }
            
            if let resetTime = resetTime, resetTime > Date() {
                Text("Next attempt available in \(timeUntilReset)")
                    .font(.caption2)
                    .foregroundColor(.bulkShareTextLight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.bulkShareWarning.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var timeUntilReset: String {
        guard let resetTime = resetTime else { return "" }
        let timeInterval = resetTime.timeIntervalSinceNow
        if timeInterval <= 0 { return "now" }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatPhoneNumber() {
        let digits = phoneNumber.filter { $0.isNumber }
        if digits.count <= 10 {
            let mask = "(XXX) XXX-XXXX"
            var result = ""
            var index = digits.startIndex
            
            for ch in mask where index < digits.endIndex {
                if ch == "X" {
                    result.append(digits[index])
                    index = digits.index(after: index)
                } else {
                    result.append(ch)
                }
            }
            phoneNumber = result
        }
    }
    
    private func sendVerificationCode() {
        isLoading = true
        errorMessage = ""
        
        // Clean phone number for verification
        let cleanPhone = "+1" + phoneNumber.filter { $0.isNumber }
        
        Task {
            do {
                let result = try await FirebaseManager.shared.sendPhoneVerification(
                    phoneNumber: cleanPhone
                )
                
                DispatchQueue.main.async {
                    self.verificationID = result.verificationID
                    self.attemptsRemaining = result.attemptsRemaining
                    if let resetTime = result.resetTime {
                        self.resetTime = Date(timeIntervalSince1970: TimeInterval(resetTime) / 1000)
                    }
                    self.showingVerificationInput = true
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func verifyCode() {
        guard !verificationID.isEmpty, verificationCode.count == 6 else { return }
        
        isLoading = true
        
        Task {
            do {
                try await FirebaseManager.shared.verifyPhoneCode(
                    verificationID: verificationID,
                    verificationCode: verificationCode,
                    purpose: purpose
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.onSuccess()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.verificationCode = ""
                }
            }
        }
    }
}

#Preview {
    PhoneVerificationView(
        purpose: .passwordReset,
        onSuccess: { },
        onCancel: { }
    )
}
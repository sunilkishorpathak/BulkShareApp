//
//  SignUpView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct SignUpView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var paypalId: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var navigateToLogin: Bool = false
    @Environment(\.dismiss) private var dismiss
    
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
                LazyVStack(spacing: 20) {
                    // Top spacing
                    Spacer()
                        .frame(height: 20)
                    
                    // Logo and Branding
                    VStack(spacing: 16) {
                        // Logo
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 70, height: 70)
                            
                            Text("🍃")
                                .font(.system(size: 35))
                        }
                        
                        // Title
                        Text("Join BulkShare")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start sharing today")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 10)
                    
                    // Sign Up Form
                    AuthFormCard {
                        VStack(spacing: 18) {
                            // Full Name Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                TextField("Enter your full name", text: $fullName)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            // PayPal ID Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PayPal ID")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                TextField("Enter your PayPal email", text: $paypalId)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                
                                Text("Used for payment settlements")
                                    .font(.caption)
                                    .foregroundColor(.bulkShareTextLight)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                
                                // Password match indicator
                                if !confirmPassword.isEmpty {
                                    HStack {
                                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(password == confirmPassword ? .green : .red)
                                        Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                            .font(.caption)
                                            .foregroundColor(password == confirmPassword ? .green : .red)
                                    }
                                }
                            }
                            
                            // Create Account Button
                            Button(action: handleSignUp) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? Color.bulkSharePrimary : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !isFormValid)
                            .animation(.easeInOut(duration: 0.2), value: isFormValid)
                            
                            // Login Link
                            HStack {
                                Text("Already have an account?")
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
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardAdaptive()
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
                if alertTitle == "Account Created!" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !fullName.isEmpty &&
               isValidEmail(email) &&
               isValidEmail(paypalId) &&
               password.count >= 6 &&
               password == confirmPassword &&
               !password.isEmpty &&
               !confirmPassword.isEmpty
    }
    
    private func handleSignUp() {
        guard isFormValid else {
            showAlert(title: "Invalid Form", message: "Please fill all fields correctly")
            return
        }
        
        isLoading = true
        
        Task {
            let result = await FirebaseManager.shared.signUp(
                email: email,
                password: password,
                fullName: fullName,
                paypalId: paypalId
            )
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.showAlert(
                        title: "Account Created!",
                        message: "Please check your email to verify your account before logging in."
                    )
                case .failure(let error):
                    self.showAlert(title: "Signup Failed", message: error.localizedDescription)
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

// MARK: - Keyboard Adaptive Modifier
extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
}

struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
    }
}

#Preview {
    NavigationView {
        SignUpView()
    }
}

//
//  LoginView.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  LoginView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToSignup: Bool = false
    @State private var navigateToForgotPassword: Bool = false
    @State private var navigateToMainApp: Bool = false

    // Remember Me
    @State private var rememberMe: Bool = false

    // Biometric
    @State private var attemptedBiometric = false

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
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    // Logo and Branding
                    VStack(spacing: 20) {
                        // Logo - Circle of Friends App Icon
                        Image("SplashIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // App Name
                        Text("BulkMates")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        // Tagline
                        Text("Plan Together, Achieve More")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Login Form
                    VStack(spacing: 20) {
                        AuthFormCard {
                            VStack(spacing: 20) {
                                // Title
                                Text("Welcome Back")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkShareTextDark)
                                
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
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
                                
                                // Password Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.bulkShareTextMedium)
                                    
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(BulkShareTextFieldStyle())
                                }
                                
                                // Forgot Password Link
                                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        navigateToForgotPassword = true
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.bulkSharePrimary)
                                }

                                // Remember Me Checkbox
                                Button(action: { rememberMe.toggle() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                            .foregroundColor(rememberMe ? .bulkSharePrimary : .gray)
                                            .font(.title3)

                                        Text("Remember Me")
                                            .font(.subheadline)
                                            .foregroundColor(.bulkShareTextDark)

                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)

                                // Login Button
                                Button(action: handleLogin) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Login")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.bulkSharePrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isLoading || email.isEmpty || password.isEmpty)
                                .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                                
                                // Sign Up Link
                                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(.bulkShareTextMedium)
                                    
                                    Button("Sign Up") {
                                        navigateToSignup = true
                                    }
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkSharePrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationDestination(isPresented: $navigateToSignup) {
            SignUpView()
        }
        .navigationDestination(isPresented: $navigateToForgotPassword) {
            ForgotPasswordView()
        }
        .navigationDestination(isPresented: $navigateToMainApp) {
            MainTabView()
        }
        .alert("Login Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadSavedCredentials()
            attemptBiometricLogin()
        }
    }

    // MARK: - Authentication Functions

    private func handleLogin() {
        // Basic validation
        guard isValidEmail(email) else {
            showAlert(message: "Please enter a valid email address")
            return
        }
        
        guard password.count >= 6 else {
            showAlert(message: "Password must be at least 6 characters")
            return
        }
        
        isLoading = true
        
        Task {
            let result = await FirebaseManager.shared.signIn(email: email, password: password)

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success:
                    // Save credentials if Remember Me is checked
                    if self.rememberMe {
                        self.saveCredentials()
                    } else {
                        self.clearSavedCredentials()
                    }

                    // Update last login date
                    if let userId = Auth.auth().currentUser?.uid {
                        self.updateLastLogin(userId: userId)
                    }

                    // Navigation handled automatically by RootView
                    break
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Remember Me Functions

    private func saveCredentials() {
        UserDefaults.standard.set(email, forKey: "savedUserId")
        UserDefaults.standard.set(AuthMethod.email.rawValue, forKey: "savedAuthMethod")
        UserDefaults.standard.set(true, forKey: "rememberMe")

        print("✅ Credentials saved for: \(email)")
    }

    private func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: "savedUserId")
        UserDefaults.standard.removeObject(forKey: "savedAuthMethod")
        UserDefaults.standard.set(false, forKey: "rememberMe")

        print("🗑️ Credentials cleared")
    }

    private func loadSavedCredentials() {
        let rememberMeEnabled = UserDefaults.standard.bool(forKey: "rememberMe")

        if rememberMeEnabled {
            if let savedEmail = UserDefaults.standard.string(forKey: "savedUserId") {
                self.email = savedEmail
                self.rememberMe = true

                print("📧 Loaded saved email: \(savedEmail)")
            }
        }
    }

    private func attemptBiometricLogin() {
        // Only attempt once per session
        guard !attemptedBiometric else { return }
        attemptedBiometric = true

        // Check if Remember Me is enabled and user has biometric enabled
        guard UserDefaults.standard.bool(forKey: "rememberMe"),
              let savedEmail = UserDefaults.standard.string(forKey: "savedUserId"),
              !savedEmail.isEmpty else {
            return
        }

        // Get the user ID from email (would need to be stored separately)
        // For now, we'll just check if biometric is generally enabled
        let biometricEnabled = BiometricAuth.shared.isAvailable()

        guard biometricEnabled else { return }

        // Attempt biometric authentication
        BiometricAuth.shared.authenticate(reason: "Log in to BulkMates") { success, error in
            if success {
                print("✅ Biometric authentication successful")
                // Email is already pre-filled from loadSavedCredentials
                // User still needs to enter password for security
            } else {
                if let error = error {
                    print("❌ Biometric authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateLastLogin(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "lastLoginDate": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating last login: \(error)")
            }
        }

        // Start session
        SessionManager.shared.startSession()
    }

    // MARK: - Helper Functions

    private func showAlert(message: String) {
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
    NavigationStack {
        LoginView()
    }
}

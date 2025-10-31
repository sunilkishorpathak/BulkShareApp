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
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var navigateToLogin: Bool = false
    @Environment(\.dismiss) private var dismiss

    // Phone number fields
    @State private var phoneNumber: String = ""
    @State private var selectedPhoneCountry: String = "US"

    // Address fields (optional)
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var selectedCountry: String = "US"
    @State private var showAddressFields: Bool = false

    @FocusState private var focusedField: Field?

    enum Field {
        case fullName, email, password, confirmPassword, phoneNumber, street, city, state, postalCode
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
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Top spacing
                    Color.clear
                        .frame(height: 20)

                    // Logo and Branding
                    VStack(spacing: 16) {
                        // Logo - Circle of Friends App Icon
                        Image("SplashIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Title
                        Text("Join BulkMates")
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
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
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
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                            }
                            
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.next)
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)

                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(BulkShareTextFieldStyle())
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.next)

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

                            // Phone Number Field (Optional)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Phone Number (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.bulkShareTextMedium)

                                HStack(spacing: 8) {
                                    // Country Code Picker
                                    Menu {
                                        ForEach(countries, id: \.code) { country in
                                            Button(action: { selectedPhoneCountry = country.code }) {
                                                Text("\(country.phoneCode) \(country.flag)  \(country.name)")
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if let country = getCountry(byCode: selectedPhoneCountry) {
                                                Text(country.phoneCode)
                                                    .fontWeight(.semibold)
                                                Text(country.flag)
                                                    .font(.title3)
                                            }
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.bulkShareTextDark)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .background(Color.bulkShareBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.bulkShareTextLight.opacity(0.3), lineWidth: 1)
                                        )
                                    }

                                    // Phone Number Input
                                    TextField("555-123-4567", text: $phoneNumber)
                                        .textFieldStyle(BulkShareTextFieldStyle())
                                        .keyboardType(.phonePad)
                                        .focused($focusedField, equals: .phoneNumber)
                                }
                            }

                            // Address Section (Optional)
                            VStack(alignment: .leading, spacing: 12) {
                                Button(action: { showAddressFields.toggle() }) {
                                    HStack {
                                        Text("Address (Optional)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.bulkShareTextMedium)

                                        Spacer()

                                        Image(systemName: showAddressFields ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.bulkShareTextMedium)
                                            .font(.caption)
                                    }
                                }

                                if showAddressFields {
                                    VStack(spacing: 12) {
                                        // Street Address
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Street Address")
                                                .font(.caption)
                                                .foregroundColor(.bulkShareTextMedium)

                                            TextField("123 Main Street", text: $street)
                                                .textFieldStyle(BulkShareTextFieldStyle())
                                                .focused($focusedField, equals: .street)
                                                .autocapitalization(.words)
                                        }

                                        // City
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("City")
                                                .font(.caption)
                                                .foregroundColor(.bulkShareTextMedium)

                                            TextField("City", text: $city)
                                                .textFieldStyle(BulkShareTextFieldStyle())
                                                .focused($focusedField, equals: .city)
                                                .autocapitalization(.words)
                                        }

                                        // State and Postal Code
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("State")
                                                    .font(.caption)
                                                    .foregroundColor(.bulkShareTextMedium)

                                                TextField("State", text: $state)
                                                    .textFieldStyle(BulkShareTextFieldStyle())
                                                    .focused($focusedField, equals: .state)
                                                    .autocapitalization(.allCharacters)
                                            }

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("Zip Code")
                                                    .font(.caption)
                                                    .foregroundColor(.bulkShareTextMedium)

                                                TextField("12345", text: $postalCode)
                                                    .textFieldStyle(BulkShareTextFieldStyle())
                                                    .focused($focusedField, equals: .postalCode)
                                                    .keyboardType(.numberPad)
                                            }
                                        }

                                        // Country Picker
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Country")
                                                .font(.caption)
                                                .foregroundColor(.bulkShareTextMedium)

                                            Menu {
                                                ForEach(countries, id: \.code) { country in
                                                    Button(action: { selectedCountry = country.code }) {
                                                        Text("\(country.flag)  \(country.name)")
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 8) {
                                                    if let country = getCountry(byCode: selectedCountry) {
                                                        Text(country.flag)
                                                        Text(country.name)
                                                            .foregroundColor(.bulkShareTextDark)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.down")
                                                        .font(.caption)
                                                        .foregroundColor(.bulkShareTextMedium)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(12)
                                                .background(Color.gray.opacity(0.08))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }

                            // Form validation status (for debugging/user feedback)
                            if !isFormValid && (!fullName.isEmpty || !email.isEmpty || !password.isEmpty || !confirmPassword.isEmpty) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Please complete:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.bulkShareTextMedium)
                                    
                                    if fullName.isEmpty {
                                        Text("• Full name is required")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if !isValidEmail(email) && !email.isEmpty {
                                        Text("• Valid email is required")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if email.isEmpty {
                                        Text("• Email is required")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if password.count < 6 && !password.isEmpty {
                                        Text("• Password must be at least 6 characters")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if password.isEmpty {
                                        Text("• Password is required")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if password != confirmPassword && !confirmPassword.isEmpty {
                                        Text("• Passwords must match")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    if confirmPassword.isEmpty && !password.isEmpty {
                                        Text("• Please confirm your password")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Create Account Button
                            Button(action: handleSignUp) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        if isFormValid {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? Color.bulkSharePrimary : Color.gray.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isFormValid ? Color.bulkSharePrimary : Color.clear, lineWidth: 2)
                                        .animation(.easeInOut(duration: 0.3), value: isFormValid)
                                )
                            }
                            .disabled(isLoading || !isFormValid)
                            .scaleEffect(isFormValid ? 1.02 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFormValid)
                            
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

                    // Minimal bottom spacing (keyboard adaptive handles the rest)
                    Color.clear
                        .frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .onSubmit {
                switch focusedField {
                case .fullName:
                    focusedField = .email
                case .email:
                    focusedField = .password
                case .password:
                    focusedField = .confirmPassword
                case .confirmPassword:
                    // Phone number is optional, skip it
                    if showAddressFields {
                        focusedField = .street
                    } else if isFormValid {
                        handleSignUp()
                    }
                case .phoneNumber:
                    if showAddressFields {
                        focusedField = .street
                    } else if isFormValid {
                        handleSignUp()
                    }
                case .street:
                    focusedField = .city
                case .city:
                    focusedField = .state
                case .state:
                    focusedField = .postalCode
                case .postalCode:
                    if isFormValid {
                        handleSignUp()
                    }
                case .none:
                    break
                }
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

            // Keyboard dismiss button
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.bulkSharePrimary)
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

        // Create address object if fields are filled
        var userAddress: Address? = nil
        if !city.isEmpty && !state.isEmpty && !postalCode.isEmpty {
            userAddress = Address(
                street: street.isEmpty ? nil : street,
                city: city,
                state: state,
                postalCode: postalCode,
                country: selectedCountry
            )
        }

        // Format phone number with country code if provided
        var fullPhoneNumber: String? = nil
        if !phoneNumber.isEmpty {
            let isdCode = getISDCode(forCountry: selectedPhoneCountry)
            fullPhoneNumber = "\(isdCode) \(phoneNumber)"
        }

        Task {
            let result = await FirebaseManager.shared.signUp(
                email: email,
                password: password,
                fullName: fullName,
                paypalId: "",
                address: userAddress,
                countryCode: selectedCountry,
                phoneNumber: fullPhoneNumber
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

#Preview {
    NavigationView {
        SignUpView()
    }
}

//
//  SocialLoginButtons.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI
import FirebaseAuth

struct SocialLoginButtons: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Apple Sign In
            SocialLoginButton(
                provider: .apple,
                isLoading: isLoading
            ) {
                handleSocialLogin(.apple)
            }
            
            // Google Sign In
            SocialLoginButton(
                provider: .google,
                isLoading: isLoading
            ) {
                handleSocialLogin(.google)
            }
            
            // Facebook Sign In
            SocialLoginButton(
                provider: .facebook,
                isLoading: isLoading
            ) {
                handleSocialLogin(.facebook)
            }
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSocialLogin(_ provider: SocialProvider) {
        isLoading = true
        
        Task {
            let result: Result<AuthDataResult, Error>
            
            switch provider {
            case .apple:
                result = await SocialAuthManager.shared.signInWithApple()
            case .google:
                result = await SocialAuthManager.shared.signInWithGoogle()
            case .facebook:
                result = await SocialAuthManager.shared.signInWithFacebook()
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    // Navigation handled by RootView
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

struct SocialLoginButton: View {
    let provider: SocialProvider
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Provider Icon
                Image(systemName: provider.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(provider.iconColor)
                    .frame(width: 24)
                
                // Loading or Text
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: provider.textColor))
                        .scaleEffect(0.8)
                } else {
                    Text("Continue with \(provider.displayName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(provider.textColor)
                }
                
                Spacer()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(provider.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(provider.borderColor, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Social Provider Configuration

enum SocialProvider {
    case apple
    case google
    case facebook
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .facebook: return "Facebook"
        }
    }
    
    var iconName: String {
        switch self {
        case .apple: return "applelogo"
        case .google: return "globe"
        case .facebook: return "f.cursive"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .apple: return .black
        case .google: return .white
        case .facebook: return Color(red: 0.26, green: 0.40, blue: 0.70)
        }
    }
    
    var textColor: Color {
        switch self {
        case .apple: return .white
        case .google: return .black
        case .facebook: return .white
        }
    }
    
    var iconColor: Color {
        switch self {
        case .apple: return .white
        case .google: return .red
        case .facebook: return .white
        }
    }
    
    var borderColor: Color {
        switch self {
        case .apple: return .clear
        case .google: return Color.gray.opacity(0.3)
        case .facebook: return .clear
        }
    }
}

#Preview {
    VStack {
        SocialLoginButtons()
    }
    .padding()
    .environmentObject(FirebaseManager.shared)
}
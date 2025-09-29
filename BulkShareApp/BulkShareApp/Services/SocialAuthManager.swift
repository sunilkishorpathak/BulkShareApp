//
//  SocialAuthManager.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import Foundation
import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

// Import this to resolve the AuthDataResult type
import Firebase

// Note: GoogleSignIn and FBSDKLoginKit imports removed - add back when configuring social login

class SocialAuthManager: NSObject, ObservableObject {
    static let shared = SocialAuthManager()
    
    @Published var isLoading = false
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async -> Result<AuthDataResult, Error> {
        return await withCheckedContinuation { continuation in
            let nonce = randomNonceString()
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            
            // Store continuation for delegate callback
            self.appleSignInContinuation = continuation
            self.currentNonce = nonce
            
            Task { @MainActor in
                authorizationController.performRequests()
            }
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async -> Result<AuthDataResult, Error> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Placeholder implementation - GoogleSignIn SDK not currently included
                let error = NSError(domain: "SocialAuth", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Google Sign In not available. Add GoogleSignIn pod and configure CLIENT_ID to enable this feature."
                ])
                continuation.resume(returning: .failure(error))
            }
        }
    }
    
    // MARK: - Facebook Sign In
    
    func signInWithFacebook() async -> Result<AuthDataResult, Error> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Placeholder implementation - FBSDKLoginKit not currently included
                let error = NSError(domain: "SocialAuth", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Facebook Sign In not available. Add FBSDKLoginKit pod and configure App ID to enable this feature."
                ])
                continuation.resume(returning: .failure(error))
            }
        }
    }
    
    // MARK: - Apple Sign In Support
    
    private var appleSignInContinuation: CheckedContinuation<Result<AuthDataResult, Error>, Never>?
    private var currentNonce: String?
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SocialAuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                appleSignInContinuation?.resume(returning: .failure(
                    NSError(domain: "SocialAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])
                ))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                appleSignInContinuation?.resume(returning: .failure(
                    NSError(domain: "SocialAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
                ))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                appleSignInContinuation?.resume(returning: .failure(
                    NSError(domain: "SocialAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])
                ))
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                         rawNonce: nonce,
                                                         fullName: appleIDCredential.fullName)
            
            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    
                    // Create user in Firestore if needed
                    let user = User(
                        id: result.user.uid,
                        name: appleIDCredential.fullName?.formatted() ?? result.user.displayName ?? "User",
                        email: result.user.email ?? appleIDCredential.email ?? "",
                        paypalId: "",
                        isEmailVerified: result.user.isEmailVerified
                    )
                    
                    try await FirebaseManager.shared.saveUser(user)
                    
                    appleSignInContinuation?.resume(returning: .success(result))
                } catch {
                    appleSignInContinuation?.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(returning: .failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SocialAuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - PersonNameComponents Extension

extension PersonNameComponents {
    func formatted() -> String {
        var components: [String] = []
        if let givenName = givenName { components.append(givenName) }
        if let familyName = familyName { components.append(familyName) }
        return components.joined(separator: " ")
    }
}
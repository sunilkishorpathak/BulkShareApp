//
//  ContentView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    @State private var navigateToLogin = false
    
    var body: some View {
        NavigationStack {
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
                
                // Main Content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo and Branding
                    VStack(spacing: 20) {
                        // Logo - Circle of Friends App Icon
                        Image("SplashIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 10)
                        
                        // App Name
                        Text("BulkMates")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)

                        // Tagline
                        Text("Connect, Plan, Collaborate")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)

                        // Use Case Icons
                        HStack(spacing: 20) {
                            UseCaseIconView(emoji: "🛒", label: "Shop")
                            UseCaseIconView(emoji: "🎉", label: "Events")
                            UseCaseIconView(emoji: "⛺", label: "Trips")
                            UseCaseIconView(emoji: "🍽️", label: "Potlucks")
                        }
                        .padding(.top, 30)
                    }
                    
                    Spacer()
                    
                    // Get Started Button (appears after loading)
                    if !isLoading {
                        Button(action: {
                            navigateToLogin = true
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkSharePrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .slide))
                    }
                    
                    // Loading Indicator
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Join groups • Share costs • Plan events • Build community")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)

                        Text("v1.1.0")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 50)
                }
                .padding()
            }
            .onAppear {
                // Simulate loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoading = false
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
        }
    }
}

// MARK: - Floating Background Elements (keep existing)
struct FloatingElementsView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 20...80))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Use Case Icon View
struct UseCaseIconView: View {
    let emoji: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 56, height: 56)

                Text(emoji)
                    .font(.system(size: 32))
            }

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

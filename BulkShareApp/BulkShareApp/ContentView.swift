//
//  ContentView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    
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
            
            // Main Content
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo and Branding
                VStack(spacing: 20) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Text("🍃")
                            .font(.system(size: 60))
                    }
                    
                    // App Name
                    Text("BulkShare")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Tagline
                    Text("Share Smarter, Waste Less")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Coming Soon Message
                VStack(spacing: 16) {
                    Text("Coming Soon")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Building the future of community bulk shopping")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
                    Text("Reduce waste • Save money • Build community")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text("v1.0.0")
                        .font(.caption2)
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
    }
}

// MARK: - Floating Background Elements
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

// MARK: - Preview
#Preview {
    ContentView()
}

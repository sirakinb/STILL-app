//
//  OnboardingView.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showSignInScreen = false
    
    var body: some View {
        ZStack {
            CalmBackgroundView()
            
            if showSignInScreen {
                // Final sign-in screen
                SignInScreenView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.move(edge: .trailing))
            } else {
                // Onboarding pages
                VStack {
                    // Skip button (only show on pages 1-3)
                    if currentPage > 0 && currentPage < 3 {
                        HStack {
                            Spacer()
                            Button("Skip") {
                                withAnimation {
                                    currentPage = 3
                                }
                            }
                            .font(.body)
                            .foregroundStyle(Color.stillAccent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        Spacer().frame(height: 50)
                    }
                    
                    TabView(selection: $currentPage) {
                        WelcomePageView()
                            .tag(0)
                        
                        MeditateYourWayPageView()
                            .tag(1)
                        
                        SetTheMoodPageView()
                            .tag(2)
                        
                        GrowYourPracticePageView()
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Page indicators
                    PageIndicator(currentPage: currentPage, totalPages: 4)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    
                    // Bottom button
                    bottomButton
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)
                    
                    // Log in link (only on welcome page)
                    if currentPage == 0 {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(Color.stillSecondaryText)
                            Button("Log in") {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showSignInScreen = true
                                }
                            }
                            .foregroundStyle(Color.stillAccent)
                            .underline()
                        }
                        .font(.footnote)
                        .padding(.bottom, 24)
                    } else {
                        Spacer().frame(height: 48)
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSignInScreen)
    }
    
    private var bottomButton: some View {
        Button {
            withAnimation {
                if currentPage < 3 {
                    currentPage += 1
                } else {
                    // Show sign-in screen instead of completing onboarding
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSignInScreen = true
                    }
                }
            }
        } label: {
            Text(buttonTitle)
                .font(.title3.weight(.semibold))
                .tracking(1)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color.stillAccent.opacity(0.85))
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
    
    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Get Started"
        case 3: return "Continue"
        default: return "Next"
        }
    }
}

// MARK: - Sign In Screen (Full Screen)
struct SignInScreenView: View {
    @Binding var hasCompletedOnboarding: Bool
    @ObservedObject var authManager = AuthenticationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                // Logo
                Image("stillapp_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 8)
                
                Text("Welcome to Still")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(Color.stillPrimaryText)
                
                Text("Sign in to sync your meditation\nprogress across devices")
                    .font(.subheadline)
                    .foregroundStyle(Color.stillSecondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.bottom, 48)
            
            // Sign in with Apple
            SignInWithAppleButton {
                hasCompletedOnboarding = true
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Error message
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 8)
            }
            
            // Terms
            Text("By continuing, you agree to our\nTerms of Service and Privacy Policy")
                .font(.caption)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .overlay {
            if authManager.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }
}

// MARK: - Page 1: Welcome
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(maxHeight: 20)
            
            // Logo
            LogoView()
                .padding(.bottom, 32)
            
            // Title
            Text("STILL")
                .font(.system(size: 40, weight: .light, design: .serif))
                .foregroundStyle(Color.stillDeepBlue)
                .tracking(14)
                .padding(.bottom, 20)
            
            // Divider
            Rectangle()
                .fill(Color.stillSecondaryText.opacity(0.3))
                .frame(width: 40, height: 1)
                .padding(.bottom, 20)
            
            // Heading
            Text("Find Stillness, Anywhere")
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundStyle(Color.stillPrimaryText)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Your personal meditation sanctuary.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.stillSecondaryText)
                .padding(.bottom, 20)
            
            // Description
            Text("Curated soundscapes, AI-generated music, and timed sessions to help you reset, refocus, and unwind.")
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            
            Spacer()
                .frame(maxHeight: 40)
        }
    }
}

// MARK: - Page 2: Curated Library
struct MeditateYourWayPageView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Preview cards
            VStack(spacing: 12) {
                LibraryPreviewRow(icon: "moon.stars", title: "Evening Unwind", duration: "12 min")
                LibraryPreviewRow(icon: "water.waves", title: "Ocean Breathing", duration: "8 min")
                LibraryPreviewRow(icon: "cloud.rain", title: "Rainfall Calm", duration: "6 min")
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 40)
            
            // Heading
            Text("Curated for Calm")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(Color.stillPrimaryText)
                .padding(.bottom, 16)
            
            // Subtitle
            Text("Ready-to-use meditation sessions.")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.stillSecondaryText)
                .padding(.bottom, 24)
            
            // Description
            Text("Choose from ocean waves, gentle rain, or guided audio. Pick your duration — 3, 5, 10 minutes or more.")
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct LibraryPreviewRow: View {
    let icon: String
    let title: String
    let duration: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.stillAccent)
                .frame(width: 40, height: 40)
                .background(Color.stillAccent.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.stillPrimaryText)
            
            Spacer()
            
            Text(duration)
                .font(.caption)
                .foregroundStyle(Color.stillSecondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.stillOverlay.opacity(0.5))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.9))
        )
    }
}

// MARK: - Page 3: Create Your Own
struct SetTheMoodPageView: View {
    @State private var selectedStyle: Int = 0
    
    private let styles = [
        ("cloud", "Ambient"),
        ("leaf", "Nature"),
        ("pianokeys", "Piano"),
        ("bell", "Tibetan")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // AI generation card
            VStack(spacing: 16) {
                // Magic wand icon
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.stillAccent)
                    .padding(.top, 20)
                
                // Style options
                HStack(spacing: 12) {
                    ForEach(0..<styles.count, id: \.self) { index in
                        StylePreviewButton(
                            icon: styles[index].0,
                            label: styles[index].1,
                            isSelected: selectedStyle == index
                        ) {
                            withAnimation { selectedStyle = index }
                        }
                    }
                }
                
                // Text field preview
                HStack {
                    Text("A calm, peaceful forest...")
                        .font(.subheadline)
                        .foregroundStyle(Color.stillSecondaryText.opacity(0.6))
                    Spacer()
                }
                .padding(12)
                .background(Color.stillOverlay.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.9))
                    .shadow(color: Color.stillDeepBlue.opacity(0.08), radius: 20, y: 8)
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            
            // Heading
            Text("Create Your Own")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(Color.stillPrimaryText)
                .padding(.bottom, 16)
            
            // Subtitle
            Text("AI-powered meditation music.")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.stillSecondaryText)
                .padding(.bottom, 24)
            
            // Description
            Text("Describe the mood you want and we'll generate a unique track just for you.")
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct StylePreviewButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.stillAccent : Color.stillOverlay.opacity(0.6))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? .white : Color.stillSecondaryText)
                }
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Color.stillSecondaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page 4: Track Your Journey
struct GrowYourPracticePageView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Stats preview card
            VStack(spacing: 20) {
                // Timer preview
                ZStack {
                    Circle()
                        .stroke(Color.stillOverlay.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.stillAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text("5:00")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundStyle(Color.stillPrimaryText)
                }
                .padding(.top, 16)
                
                // Stats row
                HStack(spacing: 24) {
                    StatPreview(value: "7", label: "Day Streak")
                    StatPreview(value: "45", label: "Minutes")
                    StatPreview(value: "12", label: "Sessions")
                }
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.9))
                    .shadow(color: Color.stillDeepBlue.opacity(0.08), radius: 20, y: 8)
            )
            .padding(.horizontal, 50)
            .padding(.bottom, 50)
            
            // Heading
            Text("Track Your Journey")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(Color.stillPrimaryText)
                .padding(.bottom, 16)
            
            // Subtitle
            Text("Build a lasting practice.")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(Color.stillSecondaryText)
                .padding(.bottom, 24)
            
            // Description
            Text("Timed sessions with calming chimes. Track your streaks, total minutes, and watch your meditation practice grow.")
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct StatPreview: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.stillAccent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.stillSecondaryText)
        }
    }
}

// MARK: - Logo View
struct LogoView: View {
    var body: some View {
        Image("stillapp_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
    }
}

// MARK: - Page Indicator
struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                if index == currentPage {
                    Capsule()
                        .fill(Color.stillDeepBlue)
                        .frame(width: 24, height: 8)
                } else {
                    Circle()
                        .fill(Color.stillSecondaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Sign In Options View
struct SignInOptionsView: View {
    @Binding var hasCompletedOnboarding: Bool
    @ObservedObject var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(Color.stillPrimaryText)
                
                Text("Sign in to sync your progress")
                    .font(.subheadline)
                    .foregroundStyle(Color.stillSecondaryText)
            }
            .padding(.top, 32)
            
            Spacer()
            
            VStack(spacing: 16) {
                // Google Sign In Button
                Button {
                    Task {
                        do {
                            try await authManager.signInWithGoogle()
                            hasCompletedOnboarding = true
                            dismiss()
                        } catch {
                            // Error is handled by authManager
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        Text("Continue with Google")
                            .font(.body.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundStyle(Color.stillPrimaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.stillSecondaryText.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Sign in with Apple
                SignInWithAppleButton {
                    hasCompletedOnboarding = true
                    dismiss()
                }
                
                // Continue as Guest
                Button {
                    authManager.continueAsGuest()
                    hasCompletedOnboarding = true
                    dismiss()
                } label: {
                    Text("Continue as Guest")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.stillAccent)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            
            // Error message
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Terms
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .background(Color.stillBackground)
        .overlay {
            if authManager.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}


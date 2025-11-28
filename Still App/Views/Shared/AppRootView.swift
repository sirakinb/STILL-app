//
//  AppRootView.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var settingsStore = AppSettingsStore()
    @StateObject private var historyStore = SessionHistoryStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Main content
            Group {
                if hasCompletedOnboarding {
                    mainTabView
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
            
            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Show splash for 2 seconds then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .environmentObject(settingsStore)
                .environmentObject(historyStore)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)

            NavigationStack {
                LibraryView()
                    .environmentObject(settingsStore)
                    .environmentObject(historyStore)
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(Tab.library)
            
            NavigationStack {
                MusicGeneratorView()
            }
            .tabItem {
                Label("Create", systemImage: "wand.and.stars")
            }
            .tag(Tab.create)

            NavigationStack {
                SettingsView()
                    .environmentObject(settingsStore)
                    .environmentObject(historyStore)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .tint(Color.stillAccent)
        .environmentObject(settingsStore)
        .environmentObject(historyStore)
    }
}

extension AppRootView {
    enum Tab {
        case home
        case library
        case create
        case settings
    }
}
// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            // Logo
            VStack(spacing: 24) {
                Image("stillapp_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                Text("STILL")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundStyle(Color.stillDeepBlue)
                    .tracking(10)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    AppRootView()
}

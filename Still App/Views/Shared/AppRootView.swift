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

    var body: some View {
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
        case settings
    }
}
#Preview {
    AppRootView()
}

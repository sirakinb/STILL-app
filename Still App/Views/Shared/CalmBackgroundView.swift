//
//  CalmBackgroundView.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI

struct CalmBackgroundView: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(Color.stillOverlay.opacity(0.2))
        .hueRotation(.degrees(animate ? 6 : -6))
        .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }

    private var gradientColors: [Color] {
        [
            .stillBackground,
            .stillSoftBeige,
            .stillDeepBlue.opacity(0.6)
        ]
    }
}

#Preview {
    CalmBackgroundView()
}

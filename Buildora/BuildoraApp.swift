//
//  BuildoraApp.swift
//  Buildora
//
//  Created by Anton Danilov on 12/3/26.
//

import SwiftUI

@main
struct BuildoraApp: App {
    @StateObject private var appState = AppState()
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .opacity(splashOpacity)
                } else {
                    rootView
                        .preferredColorScheme(appState.colorScheme)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        splashOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showSplash = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if !appState.hasCompletedOnboarding {
            OnboardingView()
                .environmentObject(appState)
        } else if !appState.isAuthenticated {
            AuthView()
                .environmentObject(appState)
        } else {
            MainTabView()
                .environmentObject(appState)
        }
    }
}

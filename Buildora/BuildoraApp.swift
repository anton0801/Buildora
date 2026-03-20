import SwiftUI

@main
struct BuildoraApp: App {
    @StateObject private var appState = AppState()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                SplashView()
                    .environmentObject(appState)
            }
        }
    }
    
}

struct MainView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
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
    
}

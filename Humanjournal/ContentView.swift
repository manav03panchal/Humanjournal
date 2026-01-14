//
//  ContentView.swift
//  Humanjournal
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var showOnboarding: Bool

    init() {
        _showOnboarding = State(initialValue: !UserSettings.shared.hasCompletedOnboarding)
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            } else {
                HomeView()
            }
        }
        .onAppear {
            setupNotificationHandler()
        }
    }

    private func setupNotificationHandler() {
        NotificationService.shared.onNotificationTapped = {
            // Navigate to entry screen - handled by HomeView
        }
    }
}

#Preview {
    ContentView()
}

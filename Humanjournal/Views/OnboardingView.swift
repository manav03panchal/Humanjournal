//
//  OnboardingView.swift
//  Humanjournal
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var currentStep = 0
    @State private var selectedUnlockDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var notificationHour = 21
    @State private var notificationMinute = 0
    @State private var isSettingUp = false

    let onComplete: () -> Void

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            progressIndicator
                .padding(.top, 20)

            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                conceptStep.tag(1)
                unlockDateStep.tag(2)
                notificationStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 20)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            Text("Welcome to\nHumanjournal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("A private space for your daily thoughts.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var conceptStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.accent)

            Text("Write Now,\nRead Later")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                conceptRow(icon: "pencil", text: "Write a short entry every day")
                conceptRow(icon: "eye.slash", text: "Entries stay hidden until unlock")
                conceptRow(icon: "calendar", text: "Read everything at year's end")
            }
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func conceptRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 32)

            Text(text)
                .font(.body)
        }
    }

    private var unlockDateStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.accent)

            Text("Set Your\nUnlock Date")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            DatePicker(
                "Unlock Date",
                selection: $selectedUnlockDate,
                in: Calendar.current.date(byAdding: .month, value: 1, to: Date())!...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            Text("This cannot be changed once set.")
                .font(.callout)
                .foregroundStyle(.red)
                .fontWeight(.medium)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var notificationStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.accent)

            Text("Daily\nReminder")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("We'll remind you to write each day.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            DatePicker(
                "Reminder Time",
                selection: Binding(
                    get: {
                        Calendar.current.date(from: DateComponents(hour: notificationHour, minute: notificationMinute)) ?? Date()
                    },
                    set: { newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        notificationHour = components.hour ?? 21
                        notificationMinute = components.minute ?? 0
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button {
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                if isSettingUp {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(currentStep < totalSteps - 1 ? "Continue" : "Get Started")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSettingUp)
        }
    }

    private func completeOnboarding() {
        isSettingUp = true

        Task {
            do {
                try DeadlineService.shared.setUnlockDate(selectedUnlockDate)
            } catch {
                // Date already set, continue
            }

            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                try? await NotificationService.shared.scheduleDailyReminder(
                    hour: notificationHour,
                    minute: notificationMinute
                )
            }

            userSettings.notificationHour = notificationHour
            userSettings.notificationMinute = notificationMinute
            userSettings.hasCompletedOnboarding = true

            await MainActor.run {
                isSettingUp = false
                onComplete()
            }
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding complete")
    }
}

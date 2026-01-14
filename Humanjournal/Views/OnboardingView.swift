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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 100)

            // Title
            Text(titles[currentStep])
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Subtitle
            Text(subtitles[currentStep])
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 12)

            Spacer()

            // Pickers
            if currentStep == 1 {
                DatePicker("", selection: $selectedUnlockDate, in: Calendar.current.date(byAdding: .month, value: 1, to: Date())!..., displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 200)
            }

            if currentStep == 2 {
                DatePicker("", selection: Binding(
                    get: { Calendar.current.date(from: DateComponents(hour: notificationHour, minute: notificationMinute)) ?? Date() },
                    set: { newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        notificationHour = components.hour ?? 21
                        notificationMinute = components.minute ?? 0
                    }
                ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 200)
            }

            Spacer()

            // Button
            Button(action: {
                if currentStep < 2 {
                    currentStep += 1
                } else {
                    completeOnboarding()
                }
            }) {
                if isSettingUp {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text(currentStep == 2 ? "Get Started" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .background(Color.black)
            .cornerRadius(14)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
            .disabled(isSettingUp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
    }

    private var titles: [String] {
        ["Humanjournal", "Pick your unlock date", "Daily reminder"]
    }

    private var subtitles: [String] {
        [
            "Write daily.\nRead at year's end.",
            "You won't be able to read your entries\nuntil this date. This cannot be changed.",
            "We'll nudge you at this time every day."
        ]
    }

    private func completeOnboarding() {
        isSettingUp = true
        Task {
            do { try DeadlineService.shared.setUnlockDate(selectedUnlockDate) } catch {}
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                try? await NotificationService.shared.scheduleDailyReminder(hour: notificationHour, minute: notificationMinute)
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

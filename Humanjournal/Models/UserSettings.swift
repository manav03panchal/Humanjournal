//
//  UserSettings.swift
//  Humanjournal
//

import Foundation

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let notificationHour = "notificationHour"
        static let notificationMinute = "notificationMinute"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let unlockDate = "unlockDate"
    }

    @Published var notificationHour: Int {
        didSet {
            defaults.set(notificationHour, forKey: Keys.notificationHour)
            Task {
                try? await NotificationService.shared.scheduleDailyReminder(
                    hour: notificationHour,
                    minute: notificationMinute
                )
            }
        }
    }

    @Published var notificationMinute: Int {
        didSet {
            defaults.set(notificationMinute, forKey: Keys.notificationMinute)
            Task {
                try? await NotificationService.shared.scheduleDailyReminder(
                    hour: notificationHour,
                    minute: notificationMinute
                )
            }
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    var unlockDate: Date? {
        get {
            defaults.object(forKey: Keys.unlockDate) as? Date
        }
        set {
            if unlockDate == nil {
                defaults.set(newValue, forKey: Keys.unlockDate)
                objectWillChange.send()
            }
        }
    }

    var isUnlocked: Bool {
        guard let unlock = unlockDate else { return false }
        return Date() >= unlock
    }

    var daysUntilUnlock: Int {
        guard let unlock = unlockDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: unlock)
        return max(0, components.day ?? 0)
    }

    private init() {
        let storedHour = defaults.object(forKey: Keys.notificationHour) as? Int
        let storedMinute = defaults.object(forKey: Keys.notificationMinute) as? Int

        self.notificationHour = storedHour ?? 21
        self.notificationMinute = storedMinute ?? 0
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }
}

//
//  NotificationService.swift
//  Humanjournal
//

import Foundation
import UserNotifications

final class NotificationService: NSObject {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let dailyReminderIdentifier = "com.humanjournal.dailyreminder"

    var onNotificationTapped: (() -> Void)?

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleDailyReminder(at time: DateComponents) async throws {
        await cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = "Take a moment to capture today's thoughts."
        content.sound = .default

        var triggerTime = time
        triggerTime.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerTime, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    func scheduleDailyReminder(hour: Int, minute: Int = 0) async throws {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        try await scheduleDailyReminder(at: components)
    }

    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }

    func isDailyReminderScheduled() async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.contains { $0.identifier == dailyReminderIdentifier }
    }

    func getScheduledReminderTime() async -> DateComponents? {
        let requests = await notificationCenter.pendingNotificationRequests()
        guard let request = requests.first(where: { $0.identifier == dailyReminderIdentifier }),
              let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            return nil
        }
        return trigger.dateComponents
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.notification.request.identifier == dailyReminderIdentifier {
            await MainActor.run {
                onNotificationTapped?()
            }
        }
    }
}

//
//  DeadlineService.swift
//  Humanjournal
//

import Foundation
import Security

enum DeadlineError: Error {
    case alreadySet
    case notSet
    case dateManipulationDetected
    case notYetUnlocked
}

final class DeadlineService {
    static let shared = DeadlineService()

    private let keychainKey = "com.humanjournal.unlockdate"
    private let userSettings = UserSettings.shared

    private init() {}

    var unlockDate: Date? {
        get {
            if let keychainDate = getUnlockDateFromKeychain() {
                return keychainDate
            }
            return userSettings.unlockDate
        }
    }

    var isUnlockDateSet: Bool {
        unlockDate != nil
    }

    func setUnlockDate(_ date: Date) throws {
        if isUnlockDateSet {
            throw DeadlineError.alreadySet
        }

        try saveUnlockDateToKeychain(date)
        userSettings.unlockDate = date
    }

    func isUnlocked() async -> Bool {
        guard let unlock = unlockDate else {
            return false
        }

        let verifiedDate = await TimeVerificationService.shared.getVerifiedDate()
        return verifiedDate >= unlock
    }

    func checkAccessAllowed() async throws {
        guard isUnlockDateSet else {
            throw DeadlineError.notSet
        }

        if await TimeVerificationService.shared.isDateManipulated() {
            throw DeadlineError.dateManipulationDetected
        }

        if await !isUnlocked() {
            throw DeadlineError.notYetUnlocked
        }
    }

    func daysUntilUnlock() async -> Int {
        guard let unlock = unlockDate else {
            return 0
        }

        let verifiedDate = await TimeVerificationService.shared.getVerifiedDate()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: verifiedDate, to: unlock)
        return max(0, components.day ?? 0)
    }

    private func saveUnlockDateToKeychain(_ date: Date) throws {
        let data = try JSONEncoder().encode(date)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw DeadlineError.alreadySet
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func getUnlockDateFromKeychain() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }

        return date
    }
}

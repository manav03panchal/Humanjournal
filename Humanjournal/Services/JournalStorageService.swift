//
//  JournalStorageService.swift
//  Humanjournal
//

import Foundation
import SwiftData

enum StorageError: Error {
    case modelContextNotAvailable
    case entryNotFound
    case saveFailed
}

@MainActor
final class JournalStorageService {
    static let shared = JournalStorageService()

    private let encryptionService = EncryptionService.shared
    private var modelContext: ModelContext?

    private init() {}

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveEntry(date: Date, content: String) throws -> JournalEntry {
        guard let context = modelContext else {
            throw StorageError.modelContextNotAvailable
        }

        try encryptionService.ensureKeyExists()
        let encryptedContent = try encryptionService.encrypt(content)

        let entry = JournalEntry(date: date, encryptedContent: encryptedContent)
        context.insert(entry)

        do {
            try context.save()
        } catch {
            throw StorageError.saveFailed
        }

        return entry
    }

    func getEntry(for date: Date) throws -> (entry: JournalEntry, content: String)? {
        guard let context = modelContext else {
            throw StorageError.modelContextNotAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<JournalEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }

        let descriptor = FetchDescriptor<JournalEntry>(predicate: predicate)

        let entries = try context.fetch(descriptor)
        guard let entry = entries.first else {
            return nil
        }

        let content = try encryptionService.decryptToString(entry.encryptedContent)
        return (entry, content)
    }

    func getAllEntries() throws -> [(entry: JournalEntry, content: String)] {
        guard let context = modelContext else {
            throw StorageError.modelContextNotAvailable
        }

        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let entries = try context.fetch(descriptor)

        return try entries.map { entry in
            let content = try encryptionService.decryptToString(entry.encryptedContent)
            return (entry, content)
        }
    }

    func updateEntry(_ entry: JournalEntry, content: String) throws {
        guard let context = modelContext else {
            throw StorageError.modelContextNotAvailable
        }

        let encryptedContent = try encryptionService.encrypt(content)
        entry.encryptedContent = encryptedContent

        do {
            try context.save()
        } catch {
            throw StorageError.saveFailed
        }
    }

    func hasEntryForToday() throws -> Bool {
        let result = try getEntry(for: Date())
        return result != nil
    }

    func getEntryCount() throws -> Int {
        guard let context = modelContext else {
            throw StorageError.modelContextNotAvailable
        }

        let descriptor = FetchDescriptor<JournalEntry>()
        return try context.fetchCount(descriptor)
    }
}

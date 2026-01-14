//
//  JournalEntry.swift
//  Humanjournal
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var encryptedContent: Data
    var createdAt: Date

    init(id: UUID = UUID(), date: Date, encryptedContent: Data, createdAt: Date = Date()) {
        self.id = id
        self.date = date
        self.encryptedContent = encryptedContent
        self.createdAt = createdAt
    }
}

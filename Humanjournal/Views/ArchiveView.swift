//
//  ArchiveView.swift
//  Humanjournal
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
private let platformSecondaryBackground = UIColor.systemGray6
#elseif os(macOS)
private let platformSecondaryBackground = NSColor.controlBackgroundColor
#endif

enum ArchiveViewMode: String, CaseIterable {
    case list = "List"
    case calendar = "Calendar"

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .calendar: return "calendar"
        }
    }
}

struct ArchiveView: View {
    @State private var entries: [(entry: JournalEntry, content: String)] = []
    @State private var selectedEntry: (entry: JournalEntry, content: String)?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var viewMode: ArchiveViewMode = .list
    @State private var selectedDate: Date = Date()

    private var entriesByDate: [Date: (entry: JournalEntry, content: String)] {
        Dictionary(uniqueKeysWithValues: entries.map { item in
            (Calendar.current.startOfDay(for: item.entry.date), item)
        })
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading entries...")
                } else if let error = errorMessage {
                    errorView(error)
                } else if entries.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle("Your Journal")
            .toolbar {
                if !entries.isEmpty && errorMessage == nil {
                    ToolbarItem(placement: .automatic) {
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(ArchiveViewMode.allCases, id: \.self) { mode in
                                Image(systemName: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
            }
            .task {
                await loadEntries()
            }
            .sheet(item: Binding(
                get: { selectedEntry.map { IdentifiableEntry(entry: $0.entry, content: $0.content) } },
                set: { selectedEntry = $0.map { ($0.entry, $0.content) } }
            )) { item in
                EntryDetailView(entry: item.entry, content: item.content)
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .list:
            entryList
        case .calendar:
            calendarView
        }
    }

    private var entryList: some View {
        List(entries, id: \.entry.id) { item in
            Button {
                selectedEntry = item
            } label: {
                EntryRow(date: item.entry.date, preview: item.content)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    private var calendarView: some View {
        VStack(spacing: 0) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            Divider()

            if let item = entriesByDate[Calendar.current.startOfDay(for: selectedDate)] {
                ScrollView {
                    Button {
                        selectedEntry = item
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(formattedDate(item.entry.date))
                                .font(.headline)

                            Text(item.content)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(5)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(platformSecondaryBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Entry",
                    systemImage: "doc.text",
                    description: Text("No journal entry for this date.")
                )
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Entries Yet",
            systemImage: "book.closed",
            description: Text("Your journal entries will appear here after you start writing.")
        )
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView(
            "Unable to Load",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private func loadEntries() async {
        isLoading = true
        errorMessage = nil

        do {
            try await DeadlineService.shared.checkAccessAllowed()
            entries = try JournalStorageService.shared.getAllEntries()
        } catch DeadlineError.notYetUnlocked {
            errorMessage = "Your journal is still locked."
        } catch DeadlineError.dateManipulationDetected {
            errorMessage = "Date manipulation detected. Please correct your device time."
        } catch {
            errorMessage = "Failed to load entries."
        }

        isLoading = false
    }
}

struct EntryRow: View {
    let date: Date
    let preview: String

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var previewText: String {
        let trimmed = preview.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            return String(trimmed.prefix(100)) + "..."
        }
        return trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedDate)
                .font(.headline)

            Text(previewText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry
    let content: String

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: entry.date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(content)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct IdentifiableEntry: Identifiable {
    let id: UUID
    let entry: JournalEntry
    let content: String

    init(entry: JournalEntry, content: String) {
        self.id = entry.id
        self.entry = entry
        self.content = content
    }
}

#Preview {
    ArchiveView()
}

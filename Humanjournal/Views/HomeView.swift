//
//  HomeView.swift
//  Humanjournal
//

import SwiftUI

struct HomeView: View {
    @State private var daysRemaining = 0
    @State private var hasWrittenToday = false
    @State private var entryCount = 0
    @State private var showingEntrySheet = false
    @State private var isUnlocked = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                if isUnlocked {
                    unlockedView
                } else {
                    countdownView
                }

                Spacer()

                if !isUnlocked {
                    writeButton
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .navigationTitle("Humanjournal")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await refreshState()
            }
            .sheet(isPresented: $showingEntrySheet) {
                EntryView { content in
                    await saveEntry(content)
                }
            }
        }
    }

    private var countdownView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("\(daysRemaining)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))

                Text(daysRemaining == 1 ? "day remaining" : "days remaining")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            statsView
        }
    }

    private var statsView: some View {
        HStack(spacing: 40) {
            statItem(value: "\(entryCount)", label: "entries")

            Divider()
                .frame(height: 40)

            statItem(
                value: hasWrittenToday ? "Done" : "Not yet",
                label: "today",
                highlight: !hasWrittenToday
            )
        }
        .padding(.top, 16)
    }

    private func statItem(value: String, label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(highlight ? .accent : .primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var unlockedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 50))
                .foregroundStyle(.accent)

            Text("Your Journal\nis Unlocked")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("\(entryCount) entries await you")
                .font(.title3)
                .foregroundStyle(.secondary)

            NavigationLink {
                ArchiveView()
            } label: {
                Text("View Entries")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 16)
        }
    }

    private var writeButton: some View {
        Button {
            showingEntrySheet = true
        } label: {
            HStack {
                Image(systemName: hasWrittenToday ? "checkmark.circle.fill" : "pencil")
                Text(hasWrittenToday ? "Edit Today's Entry" : "Write Today's Entry")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasWrittenToday ? Color(.systemGray5) : Color.accentColor)
            .foregroundStyle(hasWrittenToday ? .primary : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func refreshState() async {
        daysRemaining = await DeadlineService.shared.daysUntilUnlock()
        isUnlocked = await DeadlineService.shared.isUnlocked()

        do {
            hasWrittenToday = try JournalStorageService.shared.hasEntryForToday()
            entryCount = try JournalStorageService.shared.getEntryCount()
        } catch {
            hasWrittenToday = false
            entryCount = 0
        }
    }

    private func saveEntry(_ content: String) async {
        do {
            _ = try JournalStorageService.shared.saveEntry(date: Date(), content: content)
            await refreshState()
        } catch {
            // Handle error silently for MVP
        }
    }
}

#Preview {
    HomeView()
}

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
            VStack(spacing: 0) {
                Spacer()

                if isUnlocked {
                    unlockedContent
                } else {
                    lockedContent
                }

                Spacer()

                if !isUnlocked {
                    bottomContent
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            #if os(iOS)
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            #endif
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

    private var lockedContent: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("\(daysRemaining)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(.black)

                Text(daysRemaining == 1 ? "day left" : "days left")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 48) {
                VStack(spacing: 4) {
                    Text("\(entryCount)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                    Text("entries")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                VStack(spacing: 4) {
                    Image(systemName: hasWrittenToday ? "checkmark" : "minus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(hasWrittenToday ? .green : .gray)
                    Text("today")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var unlockedContent: some View {
        VStack(spacing: 24) {
            Text("Unlocked")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)

            Text("\(entryCount) entries")
                .font(.system(size: 17))
                .foregroundColor(.gray)

            NavigationLink {
                ArchiveView()
            } label: {
                Text("Read Your Journal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private var bottomContent: some View {
        if hasWrittenToday {
            // Already written - show done state, no button
            Text("Done for today")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.gray)
                .frame(height: 56)
        } else {
            // Not written yet - show write button
            Button {
                showingEntrySheet = true
            } label: {
                Text("Write")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(14)
            }
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
        } catch {}
    }
}

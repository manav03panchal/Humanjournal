//
//  HumanjournalApp.swift
//  Humanjournal
//

import SwiftUI
import SwiftData

@main
struct HumanjournalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([JournalEntry.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    JournalStorageService.shared.configure(with: sharedModelContainer.mainContext)
                }
                #if os(macOS)
                .frame(minWidth: 400, idealWidth: 500, minHeight: 500, idealHeight: 700)
                #endif
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 500, height: 700)
        .windowResizability(.contentSize)
        #endif
    }
}

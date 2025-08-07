import SwiftUI
import SwiftData

@main
struct ProjectChimeraApp: App {
    // This sets up the SwiftData database for the entire application.
    // The container holds all the models we defined in Models.swift.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Chimera.self,
            Task.self,
            SubTask.self,
            JournalEntry.self,
            WeeklyChallenge.self // Included for future phases
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        // The .modelContainer modifier makes the database available to all child views.
        .modelContainer(sharedModelContainer)
    }
}

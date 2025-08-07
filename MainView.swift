import SwiftUI
import SwiftData

struct MainView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared

    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                AppTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct AppTabView: View {
    @Query private var users: [User]
    private var user: User? { users.first }
    
    var body: some View {
        TabView {
            CharacterView()
                .tabItem {
                    Label("Character", systemImage: "person.fill")
                }
            
            if let user = user {
                NavigationView {
                    SpellbookView(user: user)
                }
                .tabItem {
                    Label("Spellbook", systemImage: "book.closed.fill")
                }
            } else {
                ProgressView().tabItem { Label("Spellbook", systemImage: "book.closed.fill") }
            }
            
            if let user = user {
                NavigationView {
                    CraftingView(user: user)
                }
                .tabItem {
                    Label("Crafting", systemImage: "hammer.fill")
                }
            } else {
                ProgressView().tabItem { Label("Crafting", systemImage: "hammer.fill") }
            }
            
            if let user = user {
                NavigationView {
                    QuestsView(user: user)
                }
                .tabItem {
                    Label("Quests", systemImage: "scroll.fill")
                }
            } else {
                ProgressView().tabItem { Label("Quests", systemImage: "scroll.fill") }
            }
            
            // --- NEW: Shop Tab ---
            if let user = user {
                NavigationView {
                    ShopView(user: user)
                }
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }
            } else {
                ProgressView().tabItem { Label("Shop", systemImage: "cart.fill") }
            }
            
            SanctuaryView()
                .tabItem {
                    Label("Sanctuary", systemImage: "tree.fill")
                }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [User.self, Task.self, JournalEntry.self], inMemory: true)
}

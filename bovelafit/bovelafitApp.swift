import SwiftUI
import Combine

@main
struct BovelafitApp: App {
    @StateObject private var haptics = HapticsManager()
    @StateObject private var store = PersistenceStore()
    @StateObject private var programs = ProgramRepository()
    @StateObject private var sessions = SessionRepository()
    @StateObject private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(haptics)
                .environmentObject(store)
                .environmentObject(programs)
                .environmentObject(sessions)
                .environmentObject(settings)
                .tint(ColorTokens.accent)
                               .preferredColorScheme(.dark)   // <- default dark
                               .background(ColorTokens.bg)    // consistent bg
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: AppIcons.home) }
            ProgramsScreen()
                .tabItem { Label("Programs", systemImage: AppIcons.library) }
            BuilderScreen()
                .tabItem { Label("Builder", systemImage: AppIcons.builder) }
            HistoryScreen()
                .tabItem { Label("History", systemImage: AppIcons.history) }
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: AppIcons.settings) }
        }
    }
}

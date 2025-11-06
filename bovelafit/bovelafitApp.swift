import SwiftUI
import Combine

@main
struct BovelafitApp: App {
    @StateObject private var haptics = HapticsManager()
    @StateObject private var store = PersistenceStore()
    @StateObject private var programs = ProgramRepository()
    @StateObject private var sessions = SessionRepository()
    @StateObject private var settings = SettingsViewModel()

    
    
    @State private var showprivacy = true
    @State private var showBootOverlay = true

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            Orientation.allowAll
            ? [.portrait, .landscapeLeft, .landscapeRight]
            : [.portrait]
        }
    }
    
    
    
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
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showBootOverlay = false
                        }
                    }
                }
                .fullScreenCover(isPresented: $showprivacy) {
                    PrivacyScreen(
                        startLink: AppPrivacy.privacypage,
                        onClose: { showprivacy = false }
                    )
                    .ignoresSafeArea()
                }
                .overlay {
                    if showBootOverlay { BootOverlay() }
                }
            
            
            
            
            
            
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



private struct BootOverlay: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().progressViewStyle(.circular)
                Text("Loading")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(0.9)
            }
        }
        .transition(.opacity)
    }
}

import SwiftUI
import SwiftData

// main de l'app
@main
struct swifty_proteinsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: UserAccount.self)
    }
}

// init de l'app + splash screen
// gestion du cycle de vie (foreground/background) > confidentialite de l'app (AppSecurity)
// switch entre ecran de login et ecran principal selon l'etat de l'auth (AuthStore)
struct RootView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var app = AppState()

    @State private var showingSplash = true
    private let minSplashTime: TimeInterval = 3.0

    var body: some View {
        Group {
            if showingSplash {
                SplashView()
            } else if let auth = app.auth {
                AppSwitchView()
                    .environmentObject(auth)
            } else {
                ProgressView()
            }
        }
        .feedbackOverlay(app.feedback)
        .onChange(of: scenePhase) {
            if scenePhase == .background { app.auth?.logout() }
        }
        .task {
            StartupCleanup.runIfNeeded()
            let start = Date()

            app.bootstrap(context: ctx)
            app.bindFeedback()

            let elapsed = Date().timeIntervalSince(start)
            if elapsed < minSplashTime {
                try? await Task.sleep(nanoseconds: UInt64((minSplashTime - elapsed) * 1_000_000_000))
            }

            withAnimation(.easeInOut(duration: 0.35)) {
                showingSplash = false
            }
        }
    }
}

// switch entre ecran de login et ecran principal selon l'etat de l'auth (AuthStore)
struct AppSwitchView: View {
    @EnvironmentObject var auth: AuthStore

    @ViewBuilder
    var body: some View {
        if let session = auth.session {
            HomeView(session: session) { auth.logout() }
        } else {
            LoginView()
        }
    }
}

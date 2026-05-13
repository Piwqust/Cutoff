import SwiftUI
import SwiftData

@main
struct MTTPokerTrainerApp: App {
    @State private var configStore = ConfigStore()
    @State private var progress = ProgressStore()
    @State private var router = AppRouter()
    private let modelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(configStore)
                .environment(progress)
                .environment(router)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
                .tint(AppColors.primaryMint)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
    }
}

struct RootView: View {
    @Environment(ConfigStore.self) private var config

    var body: some View {
        ZStack {
            AppBackground()
            MainTabView()
        }
        .fullScreenCover(isPresented: .constant(!config.hasOnboarded)) {
            OnboardingView()
                .environment(config)
        }
    }
}

/// Lightweight URL-deep-link router. Supports:
/// - `mttpoker://drill/<category>` — push a drill trainer for the named category.
@MainActor
@Observable
final class AppRouter {
    var pendingDrill: DrillCategory?

    func handle(url: URL) {
        guard url.scheme == "mttpoker" else { return }
        if url.host == "drill" {
            let raw = url.pathComponents.dropFirst().first ?? ""
            if let cat = DrillCategory(rawValue: raw) {
                pendingDrill = cat
            }
        }
    }
}

#Preview {
    RootView()
        .environment(ConfigStore())
        .environment(ProgressStore())
        .environment(AppRouter())
}

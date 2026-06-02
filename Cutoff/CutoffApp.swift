import SwiftUI
import SwiftData

@main
struct CutoffApp: App {
    @State private var configStore = ConfigStore()
    @State private var rangeService = RangeService()
    @State private var progressStore = ProgressStore()
    @State private var router = AppRouter()
    @State private var localization = LocalizationManager.shared
    private let modelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--icon-export") {
                IconExportView()
            } else {
                root
            }
            #else
            root
            #endif
        }
    }

    private var root: some View {
        RootView()
            .environment(configStore)
            .environment(rangeService)
            .environment(progressStore)
            .environment(router)
            .environment(localization)
            .modelContainer(modelContainer)
            .preferredColorScheme(.dark)
            .tint(AppColors.primaryMint)
            .onOpenURL { url in
                router.handle(url: url)
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
/// - `cutoff://drill/<category>` — push a drill trainer for the named category.
@MainActor
@Observable
final class AppRouter {
    var pendingDrill: DrillCategory?

    func handle(url: URL) {
        guard url.scheme == "cutoff" else { return }
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
        .environment(LocalizationManager())
}

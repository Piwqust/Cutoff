import SwiftUI

struct MainTabView: View {
    @State private var selection: Int = MainTabView.initialTab()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                if MainTabView.launchRoute == "preflop" {
                    PreflopTrainerView()
                } else if MainTabView.launchRoute == "pushfold" {
                    PushFoldTrainerView()
                } else if MainTabView.launchRoute == "stackdepth" {
                    StackDepthTrainerView()
                } else if MainTabView.launchRoute == "flop" {
                    FlopTrainerView()
                } else {
                    TrainDashboardView()
                }
            }
            .tabItem { Label("Train", systemImage: "play.fill") }
            .tag(0)

            RangesView.tabRoot()
                .tabItem { Label("Ranges", systemImage: "rectangle.grid.3x2.fill") }
                .tag(1)

            NavigationStack { ReviewView() }
                .tabItem { Label("Review", systemImage: "exclamationmark.bubble.fill") }
                .tag(2)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(AppColors.primaryMint)
    }

    /// Read `-tab <index>` from launch arguments. Used by screenshot tooling
    /// in `docs/screenshots/`. Falls back to the Train tab.
    private static func initialTab() -> Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let n = Int(args[i + 1]) {
            return min(max(n, 0), 3)
        }
        return 0
    }

    /// Optional `-route <name>` launch argument used to deep-link the Train tab
    /// for screenshot tooling. Values: "preflop", "pushfold", "stackdepth".
    static let launchRoute: String? = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-route"), i + 1 < args.count {
            return args[i + 1]
        }
        return nil
    }()
}

#Preview {
    MainTabView()
        .environment(ConfigStore())
}

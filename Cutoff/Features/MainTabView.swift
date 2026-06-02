import SwiftUI

struct MainTabView: View {
    @State private var selection: Int = 0
    @State private var trainPath = NavigationPath()
    @Environment(AppRouter.self) private var router
    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $trainPath) {
                TrainDashboardView()
                    .navigationDestination(for: DrillCategory.self) { cat in
                        DrillTrainerView(category: cat)
                    }
            }
            .tabItem { Label(l10n.t(.tabTrain), systemImage: "play.fill") }
            .tag(0)

            RangesView.tabRoot()
                .tabItem { Label(l10n.t(.tabRanges), systemImage: "rectangle.grid.3x2.fill") }
                .tag(1)

            NavigationStack { ReviewView() }
                .tabItem { Label(l10n.t(.tabReview), systemImage: "exclamationmark.bubble.fill") }
                .tag(2)

            NavigationStack { StrategyGuideView() }
                .tabItem { Label(l10n.t(.tabStrategy), systemImage: "map.fill") }
                .tag(3)
        }
        .tint(AppColors.primaryMint)
        .onChange(of: router.pendingDrill) { _, newValue in
            guard let cat = newValue else { return }
            selection = 0
            trainPath = NavigationPath()
            trainPath.append(cat)
            router.pendingDrill = nil
        }
    }
}

#Preview {
    MainTabView()
        .environment(ConfigStore())
        .environment(ProgressStore())
        .environment(AppRouter())
        .environment(LocalizationManager())
}

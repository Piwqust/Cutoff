import SwiftUI
import SwiftData

@main
struct MTTPokerTrainerApp: App {
    @State private var configStore = ConfigStore()
    private let modelContainer = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(configStore)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
                .tint(AppColors.primaryMint)
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

#Preview {
    RootView()
        .environment(ConfigStore())
}

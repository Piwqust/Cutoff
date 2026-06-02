import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSetup = false
    @State private var showingResetConfirm = false
    @State private var showingClearStatsConfirm = false

    // App Icons
    struct AppIconOption: Hashable {
        let name: String
        let altName: String?
        let previewImage: String
    }
    
    let appIcons = [
        AppIconOption(name: "Classic", altName: nil, previewImage: "AppIconPreviewClassic.png"),
        AppIconOption(name: "Neon", altName: "AppIconNeon", previewImage: "AppIconPreviewNeon.png"),
        AppIconOption(name: "Dark", altName: "AppIconDark", previewImage: "AppIconPreviewDark.png")
    ]
    
    @State private var activeIconName: String? = UIApplication.shared.alternateIconName

    var body: some View {
        ZStack {
            // No background — the presenting sheet supplies its own surface.
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    
                    // Tournament Section
                    sectionHeader(title: l10n.t(.settingsTournamentSection))
                    TournamentSummaryCard(
                        stack: config.config.startingStack,
                        smallBlind: config.config.smallBlind,
                        bigBlind: config.config.bigBlind,
                        tableSize: config.config.tableSize,
                        bbCount: config.config.startingBB,
                        levelMinutes: config.config.blindLevelDuration.minutes
                    )
                    
                    SecondaryButton(title: l10n.t(.editTournamentRules)) {
                        showingSetup = true
                    }
                    
                    // Appearance Section
                    sectionHeader(title: l10n.t(.settingsAppearanceSection))
                    appIconSelector
                    languageCard

                    // Preferences Section
                    sectionHeader(title: l10n.t(.settingsPreferencesSection))
                    preferencesCard
                    
                    // Data Section
                    sectionHeader(title: l10n.t(.settingsDataSection))
                    clearStatsCard

                    // About Section
                    sectionHeader(title: l10n.t(.settingsAboutSection))
                    
                    GlassCard {
                        VStack(spacing: AppSpacing.md) {
                            // App Info
                            VStack(spacing: 4) {
                                Image(systemName: "suit.spade.fill")
                                    .font(.title)
                                    .foregroundStyle(AppColors.primaryMint)
                                    .padding(.bottom, AppSpacing.xs)
                                
                                Text("Cutoff")
                                    .font(AppTypography.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Text(l10n.t(.appTagline))
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                    Text("\(l10n.t(.version)) \(version)")
                                        .font(AppTypography.footnote)
                                        .foregroundStyle(AppColors.textSecondary)
                                        .padding(.top, AppSpacing.xs)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            
                            Divider().overlay(AppColors.divider)
                            
                            // Reset Onboarding
                            Button {
                                showingResetConfirm = true
                            } label: {
                                HStack(spacing: AppSpacing.md) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title3)
                                        .foregroundStyle(AppColors.textPrimary)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(l10n.t(.resetOnboarding))
                                            .font(AppTypography.body)
                                            .foregroundStyle(AppColors.textPrimary)
                                        
                                        Text(l10n.t(.resetOnboardingSubtitle))
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, AppSpacing.xs)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .confirmationDialog(l10n.t(.resetOnboarding), isPresented: $showingResetConfirm) {
                                Button(l10n.t(.resetOnboarding), role: .destructive) {
                                    config.hasOnboarded = false
                                }
                                Button(l10n.t(.cancel), role: .cancel) {}
                            } message: {
                                Text(l10n.t(.resetOnboardingSubtitle))
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(l10n.t(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .accessibilityLabel(l10n.t(.done))
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: $showingSetup) {
            TournamentSetupView()
                .environment(config)
                .environment(l10n)
        }
    }
    
    @ViewBuilder
    private func sectionHeader(title: String) -> some View {
        Text(title.uppercased())
            .font(AppTypography.caption)
            .bold()
            .foregroundStyle(AppColors.textSecondary)
            .tracking(1.0)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.top, AppSpacing.sm)
    }
    
    // MARK: - App Icon Selector
    private var appIconSelector: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t(.appIcon))
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(l10n.t(.appIconSubtitle))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(appIcons, id: \.self) { icon in
                            Button {
                                UIApplication.shared.setAlternateIconName(icon.altName) { error in
                                    if let error = error {
                                        print("Failed to set alternate icon: \(error)")
                                    } else {
                                        activeIconName = UIApplication.shared.alternateIconName
                                    }
                                }
                            } label: {
                                VStack {
                                    if let uiImage = UIImage(named: icon.previewImage) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(activeIconName == icon.altName ? AppColors.primaryMint : AppColors.divider, lineWidth: activeIconName == icon.altName ? 2 : 1)
                                            )
                                    } else {
                                        // Fallback if image asset is missing
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(AppColors.backgroundDeep)
                                            .frame(width: 56, height: 56)
                                            .overlay(
                                                Image(systemName: "app.fill")
                                                    .font(.title)
                                                    .foregroundStyle(activeIconName == icon.altName ? AppColors.primaryMint : AppColors.divider)
                                            )
                                    }
                                    
                                    Text(icon.name == "Classic" ? l10n.t(.appIconClassic) : icon.name)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(activeIconName == icon.altName ? AppColors.textPrimary : AppColors.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Language Card
    private var languageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(l10n.t(.language))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            l10n.language = lang
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                if l10n.language == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColors.primaryMint)
                                }
                            }
                            .padding(.vertical, AppSpacing.xs)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if lang != AppLanguage.allCases.last {
                            Divider().overlay(AppColors.divider)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Preferences
    private var preferencesCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                @Bindable var bindableConfig = config
                
                SettingsToggleRow(
                    title: l10n.t(.haptics),
                    subtitle: l10n.t(.hapticsSubtitle),
                    icon: "hand.tap.fill",
                    isOn: $bindableConfig.hapticsEnabled
                )
                
                Divider().overlay(AppColors.divider)
                    .padding(.vertical, AppSpacing.xs)
                
                SettingsToggleRow(
                    title: l10n.t(.sounds),
                    subtitle: l10n.t(.soundsSubtitle),
                    icon: "speaker.wave.2.fill",
                    isOn: $bindableConfig.soundEnabled
                )
            }
        }
    }
    
    // MARK: - Data Section
    private var clearStatsCard: some View {
        GlassCard {
            Button {
                showingClearStatsConfirm = true
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.errorSoft)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.t(.clearHistory))
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColors.errorSoft)
                        
                        Text(l10n.t(.clearHistorySubtitle))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, AppSpacing.xs)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .confirmationDialog(l10n.t(.clearHistoryConfirmTitle), isPresented: $showingClearStatsConfirm, titleVisibility: .visible) {
                Button(l10n.t(.clearHistory), role: .destructive) {
                    clearSwiftData()
                }
                Button(l10n.t(.cancel), role: .cancel) {}
            } message: {
                Text(l10n.t(.clearHistoryConfirmMessage))
            }
        }
    }
    
    // MARK: - SwiftData Deletion
    private func clearSwiftData() {
        do {
            try modelContext.delete(model: QuizResult.self)
            try modelContext.delete(model: TrainingSession.self)
            try modelContext.delete(model: PostflopDrillSession.self)
            try modelContext.delete(model: PostflopResult.self)
            try modelContext.save()
        } catch {
            print("Failed to clear stats: \(error)")
        }
    }
}

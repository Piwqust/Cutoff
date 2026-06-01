import SwiftUI

struct StrategyGuideView: View {
    @Environment(LocalizationManager.self) private var l10n
    @Environment(ConfigStore.self) private var config
    
    @State private var selectedGuide: WeeklyGuide = StrategyStore.activeGuide
    @State private var showingSettings = false
    
    // Toggle state used to trigger list redraw when popping back from detail view
    @State private var refreshTrigger = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    
                    // Week Selector Dropdown Menu
                    weekSelectorMenu
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(l10n.language == .english ? "CHAPTERS" : "ГЛАВЫ ОБУЧЕНИЯ")
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.textSecondary)
                            .tracking(1.0)
                            .padding(.horizontal, 4)
                        
                        // List of Chapters as NavLinks
                        VStack(spacing: AppSpacing.md) {
                            ForEach(selectedGuide.chapters) { chapter in
                                let isCompleted = checkCompletionStatus(for: chapter.id)
                                
                                NavigationLink(
                                    destination: StrategyChapterDetailView(
                                        chapter: chapter,
                                        weekId: selectedGuide.id
                                    )
                                ) {
                                    HStack(spacing: AppSpacing.md) {
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            HStack {
                                                // Category Tag Badge
                                                Text(chapter.tag.uppercased())
                                                    .font(AppTypography.caption)
                                                    .bold()
                                                    .foregroundStyle(AppColors.primaryMint)
                                                    .padding(.horizontal, AppSpacing.xs)
                                                    .padding(.vertical, 2)
                                                    .background(AppColors.primaryMint.opacity(0.12))
                                                    .clipShape(Capsule())
                                                
                                                Spacer()
                                                
                                                // Dynamic studied checkmark
                                                if isCompleted {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundStyle(AppColors.accentLime)
                                                        Text(l10n.language == .english ? "Studied" : "Изучено")
                                                            .font(AppTypography.caption)
                                                            .bold()
                                                            .foregroundStyle(AppColors.accentLime)
                                                    }
                                                    .padding(.horizontal, AppSpacing.xs)
                                                    .padding(.vertical, 2)
                                                    .background(AppColors.accentLime.opacity(0.15))
                                                    .clipShape(Capsule())
                                                }
                                            }
                                            
                                            // Chapter Title
                                            Text(chapter.title(for: l10n.language))
                                                .font(AppTypography.headline)
                                                .foregroundStyle(AppColors.textPrimary)
                                                .multilineTextAlignment(.leading)
                                            
                                            // 1-line Description preview
                                            Text(chapter.shortDescription(for: l10n.language))
                                                .font(AppTypography.footnote)
                                                .foregroundStyle(AppColors.textSecondary)
                                                .lineLimit(1)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        // Disclosure chevron
                                        Image(systemName: "chevron.right")
                                            .font(.footnote)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    .padding(AppSpacing.md)
                                    .glassBackground(cornerRadius: AppRadius.card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .id(refreshTrigger) // Redraw list when state changes
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .navigationTitle(selectedGuide.title(for: l10n.language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppColors.primaryMint)
                }
                .accessibilityLabel(l10n.t(.settingsTitle))
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            .environment(config)
            .environment(l10n)
        }
        .onAppear {
            // Force redraw on appear to update checkmark statuses when popping back from detail screens
            refreshTrigger.toggle()
        }
    }
    
    // MARK: - Week Dropdown Menu
    private var weekSelectorMenu: some View {
        Menu {
            ForEach(StrategyStore.allGuides) { guide in
                Button(action: {
                    withAnimation {
                        selectedGuide = guide
                        refreshTrigger.toggle()
                    }
                }) {
                    HStack {
                        Text(guide.subtitle(for: l10n.language))
                        if selectedGuide.id == guide.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppColors.primaryMint)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t(.pastGuides))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(selectedGuide.subtitle(for: l10n.language))
                        .font(AppTypography.subheadline)
                        .bold()
                        .foregroundStyle(AppColors.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .glassBackground(cornerRadius: AppRadius.card)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper to check completion status
    private func checkCompletionStatus(for chapterId: Int) -> Bool {
        return UserDefaults.standard.bool(forKey: "strategy.completed.\(selectedGuide.id).\(chapterId)")
    }
}

#Preview {
    NavigationStack {
        StrategyGuideView()
            .environment(ConfigStore())
            .environment(LocalizationManager())
    }
}

import SwiftUI

struct TournamentSetupView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.dismiss) private var dismiss

    @State private var draft: TournamentConfig = .default
    @State private var heroStackText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        TournamentSummaryCard(
                            stack: draft.startingStack,
                            smallBlind: draft.smallBlind,
                            bigBlind: draft.bigBlind,
                            tableSize: draft.tableSize,
                            bbCount: draft.startingBB,
                            levelMinutes: draft.blindLevelDuration.minutes
                        )

                        stackCard
                        blindsCard
                        tableCard
                        levelCard
                        anteCard
                        heroStackCard

                        PrimaryButton(title: l10n.t(.saveProfile), systemImage: "checkmark.circle.fill") {
                            commit()
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                    .padding(.horizontal, AppSpacing.pageHorizontal)
                    .padding(.vertical, AppSpacing.lg)
                }
            }
            .navigationTitle(l10n.t(.tournamentProfile))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.t(.cancel)) { dismiss() }
                        .tint(AppColors.textSecondary)
                }
            }
            .onAppear {
                draft = config.config
                if let hero = draft.currentHeroStack { heroStackText = String(hero) }
            }
        }
    }

    // MARK: - Cards

    private var stackCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                cardTitle(l10n.t(.startingStack))
                Stepper(value: $draft.startingStack, in: 1_000...500_000, step: 1_000) {
                    Text(draft.startingStack.formatted(.number))
                        .font(AppTypography.numericMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.primaryMint)
            }
        }
    }

    private var blindsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                cardTitle(l10n.t(.blinds))
                HStack(spacing: AppSpacing.md) {
                    blindStepper(label: l10n.t(.blindSmall), value: $draft.smallBlind, in: 25...10_000, step: 25)
                    blindStepper(label: l10n.t(.blindBig),   value: $draft.bigBlind,   in: 50...20_000, step: 50)
                }
                Text(L10n.startingBB(draft.startingBB, in: l10n.language))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.primaryMint)
            }
        }
    }

    private func blindStepper(label: String, value: Binding<Int>, in range: ClosedRange<Int>, step: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Stepper(value: value, in: range, step: step) {
                Text(String(value.wrappedValue))
                    .font(AppTypography.numericMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.primaryMint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tableCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                cardTitle(l10n.t(.tableSize))
                Picker(l10n.t(.tableSize), selection: $draft.tableSize) {
                    Text(l10n.t(.tableSize6)).tag(6)
                    Text(l10n.t(.tableSize8)).tag(8)
                    Text(l10n.t(.tableSize9)).tag(9)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var levelCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                cardTitle(l10n.t(.blindLevelDuration))
                Picker(l10n.t(.blindLevelDuration), selection: $draft.blindLevelDuration) {
                    ForEach(BlindLevelDuration.allCases) { dur in
                        Text(dur.label).tag(dur)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var anteCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                cardTitle(l10n.t(.ante))
                VStack(spacing: 0) {
                    ForEach(AnteType.allCases) { type in
                        Button {
                            draft.anteType = type
                        } label: {
                            HStack {
                                Text(type.displayName(in: l10n.language))
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                if draft.anteType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColors.primaryMint)
                                }
                            }
                            .padding(.vertical, AppSpacing.sm)
                        }
                        .buttonStyle(.plain)
                        if type != AnteType.allCases.last {
                            Divider().overlay(AppColors.divider)
                        }
                    }
                }
            }
        }
    }

    private var heroStackCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                cardTitle(l10n.t(.currentHeroStack))
                HStack {
                    TextField(l10n.t(.heroStackPlaceholder), text: $heroStackText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .font(AppTypography.numericMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.vertical, AppSpacing.xs)
                        .padding(.horizontal, AppSpacing.sm)
                        .background(RoundedRectangle(cornerRadius: AppRadius.chip).fill(AppColors.cardSurface))
                    if let hero = Int(heroStackText), draft.bigBlind > 0 {
                        Text(L10n.bbValue(BBCalculator.bb(stack: hero, bigBlind: draft.bigBlind), in: l10n.language))
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.primaryMint)
                    }
                }
            }
        }
    }

    private func cardTitle(_ s: String) -> some View {
        Text(s)
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textSecondary)
    }

    private func commit() {
        // Keep big blind a multiple of small blind for sanity; not enforced strictly.
        var c = draft
        c.currentHeroStack = Int(heroStackText)
        config.update { $0 = c }
        dismiss()
    }
}

#Preview {
    TournamentSetupView()
        .environment(ConfigStore())
        .environment(LocalizationManager())
}

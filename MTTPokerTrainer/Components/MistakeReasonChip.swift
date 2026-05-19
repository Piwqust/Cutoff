import SwiftUI

/// Compact pill summarizing the *kind* of error (too tight / too loose / missed
/// mix / over-commit / under-commit / wrong line). Color-coded against the
/// outcome palette.
struct MistakeReasonChip: View {
    let reason: MistakeReason
    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: glyph)
                .font(AppTypography.caption.weight(.bold))
            Text(reason.shortLabel(in: l10n.language))
                .font(AppTypography.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.16)))
        .accessibilityLabel(reason.displayName(in: l10n.language))
    }

    private var tint: Color {
        switch reason {
        case .correct:      return AppColors.primaryMint
        case .missedMix:    return AppColors.accentLime
        case .tooTight:     return AppColors.accentPeach
        case .tooLoose:     return AppColors.accentCoral
        case .wrongLine:    return AppColors.textSecondary
        case .overcommit:   return AppColors.actionJam
        case .undercommit:  return AppColors.actionCall
        }
    }

    private var glyph: String {
        switch reason {
        case .correct:      return "checkmark"
        case .missedMix:    return "circle.lefthalf.filled"
        case .tooTight:     return "lock"
        case .tooLoose:     return "lock.open"
        case .wrongLine:    return "arrow.triangle.branch"
        case .overcommit:   return "arrow.up.right.circle"
        case .undercommit:  return "arrow.down.right.circle"
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack {
            ForEach(MistakeReason.allCases) { r in
                MistakeReasonChip(reason: r)
            }
        }
        .padding(AppSpacing.lg)
    }
    .environment(LocalizationManager())
}

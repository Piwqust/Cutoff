import re

files_to_fix = [
    "MTTPokerTrainer/Features/Train/PreflopTrainerView.swift",
    "MTTPokerTrainer/Features/Train/StackDepthTrainerView.swift",
    "MTTPokerTrainer/Features/Train/PushFoldTrainerView.swift",
    "MTTPokerTrainer/Features/Ranges/RangesView.swift",
    "MTTPokerTrainer/Features/Settings/SettingsView.swift",
    "MTTPokerTrainer/Features/Review/ReviewView.swift",
    "MTTPokerTrainer/Features/Onboarding/OnboardingView.swift"
]

for f in files_to_fix:
    with open(f, "r") as file:
        content = file.read()

    # PreflopTrainerView
    content = re.sub(r'disclaimer\n', '', content)
    content = re.sub(r'private var disclaimer: some View \{\n.*?\.font\(AppTypography\.caption\)\n.*?\.foregroundStyle\(AppColors\.textSecondary\)\n.*?\.frame\(maxWidth: \.infinity, alignment: \.center\)\n\s*\}', '', content, flags=re.DOTALL)
    
    # StackDepthTrainerView / PushFoldTrainerView
    content = re.sub(r'\.font\(AppTypography\.caption\)\n.*?\.foregroundStyle\(AppColors\.textSecondary\)\n.*?\.frame\(maxWidth: \.infinity, alignment: \.center\)\n.*?\.padding\(\.top, AppSpacing\.md\)', '', content, flags=re.DOTALL)

    # RangesView
    content = re.sub(r'\.font\(AppTypography\.caption\)\n.*?\.foregroundStyle\(AppColors\.textSecondary\)\n.*?\.multilineTextAlignment\(\.center\)', '', content, flags=re.DOTALL)
    
    # RangeDetailSheet (inside RangesView)
    content = re.sub(r'Text\(payload\.chart\.source\.fullDisclaimer\)\n.*?\.font\(AppTypography\.caption\)\n.*?\.foregroundStyle\(AppColors\.textSecondary\)', '', content, flags=re.DOTALL)

    # SettingsView
    content = re.sub(r'\.font\(AppTypography\.caption\)\n.*?\.foregroundStyle\(AppColors\.textSecondary\)\n.*?\.multilineTextAlignment\(\.center\)\n.*?\.padding\(\.horizontal, AppSpacing\.xl\)\n.*?\.padding\(\.top, AppSpacing\.xl\)', '', content, flags=re.DOTALL)
    
    # ReviewView
    content = re.sub(r'\.font\(AppTypography\.caption\)\n.*?\.foregroundStyle\(AppColors\.textSecondary\)\n.*?\.multilineTextAlignment\(\.center\)\n.*?\.padding\(\.horizontal, AppSpacing\.xl\)', '', content, flags=re.DOTALL)
    
    # OnboardingView
    content = re.sub(r'\.accessibilityLabel\(AppTheme\.fullLegalLine\)', '', content, flags=re.DOTALL)

    with open(f, "w") as file:
        file.write(content)


# Screenshots

Simulator captures live here. To regenerate:

```sh
xcrun simctl boot "iPhone 17"
xcodebuild -project ../../Cutoff.xcodeproj \
  -scheme Cutoff \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath ./build install

xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/Cutoff.app
xcrun simctl launch booted com.cutoff.app
# Drive the app to each screen, then for each:
xcrun simctl io booted screenshot 01_onboarding.png
xcrun simctl io booted screenshot 02_train_dashboard.png
xcrun simctl io booted screenshot 03_preflop_trainer.png
xcrun simctl io booted screenshot 04_range_grid.png
xcrun simctl io booted screenshot 05_review.png
xcrun simctl io booted screenshot 06_settings.png
```

If screenshots are missing from this directory after the initial build, automated capture was unavailable in the build environment (no booted simulator, no simctl availability, or the build did not succeed). The build/test result line in the final summary will explain which.

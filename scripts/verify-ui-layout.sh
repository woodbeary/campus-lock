#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if rg -q "$pattern" "$file"; then
    echo "✓ ${description}"
  else
    echo "✗ ${description}"
    echo "  Missing pattern '${pattern}' in ${file}."
    failures=$((failures + 1))
  fi
}

reject_pattern() {
  local file_glob="$1"
  local pattern="$2"
  local description="$3"
  local matches

  matches="$(rg -n "$pattern" $file_glob || true)"
  if [[ -z "$matches" ]]; then
    echo "✓ ${description}"
  else
    echo "✗ ${description}"
    echo "$matches"
    failures=$((failures + 1))
  fi
}

echo "== Fixed footer menu =="
require_pattern "CampusLock/Features/RootView.swift" "struct CampusFooterMenu" "Root defines a fixed bottom footer menu."
require_pattern "CampusLock/Features/RootView.swift" "safeAreaInset\\(edge: \\.bottom" "Root reserves safe area for the footer."
require_pattern "CampusLock/Features/RootView.swift" "if store\\.shouldShowSetup" "Root gates onboarding before the main footer."
require_pattern "CampusLock/Features/RootView.swift" "accessibilityIdentifier\\(\"footer.menu\"\\)" "Footer has a stable accessibility identifier."
require_pattern "CampusLock/Features/RootView.swift" "accessibilityIdentifier\\(\"tab" "Footer tabs have stable accessibility identifiers."
reject_pattern "CampusLock/Features/RootView.swift" "TabView\\(" "Root avoids fragile tab-bar cropping."

echo "== Fixed action shell =="
require_pattern "CampusLock/Features/CampusTheme.swift" "struct CampusScreen<Content: View>" "Shared scroll shell exists."
require_pattern "CampusLock/Features/CampusTheme.swift" "safeAreaInset\\(edge: \\.bottom" "Primary actions use bottom safe-area inset."
require_pattern "CampusLock/Features/CampusTheme.swift" "struct CampusBottomBar<Content: View>" "Fixed action dock exists."
reject_pattern "CampusLock/Features/*.swift" "GeometryReader" "Feature screens avoid GeometryReader-driven crowding."

echo "== Screen adoption =="
for view in Setup Apps Zone Attendance Insights; do
  require_pattern "CampusLock/Features/${view}View.swift" "CampusScreen \\{" "${view} screen uses the shared shell."
done
require_pattern "CampusLock/Features/LockView.swift" "CampusScreen \\{" "Lock ready/unlocked states use the shared shell."

echo "== UI regression tests =="
require_pattern "CampusLockUITests/CampusLockUITests.swift" "testSetupScreenHidesFooterAndKeepsFixedAction" "Setup footer/action regression test exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "onboarding should not show the main footer" "Onboarding hides footer assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "assertFooterTabsStayReachable" "Footer reachability assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "footer.menu" "Fixed footer menu assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "assertActionSitsAboveFooter" "Fixed action placement assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "should not be cropped" "Crop guard assertions exist."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "Recommended Focus" "Default recommended preset assertion exists."

echo "== Full-screen launch =="
require_pattern "CampusLock/Info.plist" "UILaunchScreen" "Info.plist declares a modern launch screen to avoid iPhone letterboxing."
require_pattern "project.yml" "UILaunchScreen: \\{\\}" "XcodeGen manifest preserves the launch screen declaration."

echo "== Location permissions =="
require_pattern "CampusLock/Info.plist" "NSLocationAlwaysAndWhenInUseUsageDescription" "Info.plist declares Always Location usage."
require_pattern "CampusLock/Info.plist" "UIBackgroundModes" "Info.plist declares background location mode for geofence exit unlock."
require_pattern "CampusLock/Services/LocationController.swift" "Allow Always" "Location setup distinguishes foreground access from Always access."

if (( failures > 0 )); then
  echo "UI layout verification failed with ${failures} issue(s)."
  exit 1
fi

echo "UI layout verification passed."

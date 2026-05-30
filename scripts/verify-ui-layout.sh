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

echo "== One-screen navigation =="
require_pattern "CampusLock/Features/RootView.swift" "if store\\.shouldShowPermissionSetup" "Root gates permission onboarding before home."
require_pattern "CampusLock/Features/RootView.swift" "ZoneView\\(mode: \\.onboarding\\)" "Root keeps zone setup inside onboarding."
require_pattern "CampusLock/Features/RootView.swift" "AttendanceView\\(\\)" "Root opens directly to attendance home after setup."
reject_pattern "CampusLock/Features/RootView.swift" "CampusFooterMenu" "Root avoids an unnecessary settings footer."
reject_pattern "CampusLock/Features/*.swift" "footer\\.menu" "No feature exposes a bottom settings footer."
require_pattern "CampusLock/Features/AttendanceView.swift" "accessibilityIdentifier\\(\"home\\.settings\"\\)" "Home owns a stable settings gear."
require_pattern "CampusLock/Features/AttendanceView.swift" "campusGlass\\(cornerRadius: 24, interactive: true\\)" "Home settings gear uses Liquid Glass."
reject_pattern "CampusLock/Features/RootView.swift" "TabView\\(" "Root avoids fragile tab-bar cropping."

echo "== Fixed action shell =="
require_pattern "CampusLock/Features/CampusTheme.swift" "struct CampusScreen<Content: View>" "Shared scroll shell exists."
require_pattern "CampusLock/Features/CampusTheme.swift" "safeAreaInset\\(edge: \\.bottom" "Primary actions use bottom safe-area inset."
require_pattern "CampusLock/Features/CampusTheme.swift" "struct CampusBottomBar<Content: View>" "Fixed action dock exists."
require_pattern "CampusLock/Features/CampusTheme.swift" "GlassEffectContainer" "Native Liquid Glass grouping is used when available."
require_pattern "CampusLock/Features/CampusTheme.swift" "buttonStyle\\(\\.glassProminent\\)" "Primary actions use native glass buttons when available."
require_pattern "CampusLock/Features/CampusTheme.swift" "buttonStyle\\(\\.glass\\)" "Secondary actions use native glass buttons when available."
reject_pattern "CampusLock/Features/*.swift" "background\\(\\.bar\\)" "Screens avoid mismatched bottom bar color strips."
reject_pattern "CampusLock/Features/*.swift" "GeometryReader" "Feature screens avoid GeometryReader-driven crowding."

echo "== Screen adoption =="
for view in Apps Zone Attendance Insights; do
  require_pattern "CampusLock/Features/${view}View.swift" "CampusScreen \\{" "${view} screen uses the shared shell."
done
reject_pattern "CampusLock/Features/SetupView.swift" "Required setup\\." "Setup avoids wordy required setup copy."
reject_pattern "CampusLock/Features/SetupView.swift" "Locks apps during class" "Setup avoids redundant explanatory copy."
require_pattern "CampusLock/Features/SetupView.swift" "disabled\\(!store\\.canContinuePermissionOnboarding\\)" "Setup continue stays disabled until permissions are complete."
require_pattern "CampusLock/App/CampusLockStore.swift" "var screenTimeReady: Bool \\{" "Screen Time readiness is explicit."
reject_pattern "CampusLock/App/CampusLockStore.swift" "authorizationStatus\\.isUsable \\|\\| hasShieldSelection" "Saved app selections cannot bypass Screen Time permission."
require_pattern "CampusLock/Features/AttendanceView.swift" "attendance\\.hallPass" "Attendance exposes a hall pass action during class."
require_pattern "CampusLock/Features/AttendanceView.swift" "attendance\\.locating" "Attendance shows a loading state while locating."
require_pattern "CampusLock/Features/AttendanceView.swift" "case \\.exit:" "Exit requires confirmation."
reject_pattern "CampusLock/Features/AttendanceView.swift" "CampusScreenHeader" "Home avoids a redundant top title block."
require_pattern "CampusLock/Features/AppsView.swift" "settings\\.zone" "Settings exposes geofence setup."
require_pattern "CampusLock/Features/AppsView.swift" "settings\\.stats" "Settings exposes stats without a footer tab."
reject_pattern "CampusLock/Features/AppsView.swift" "Emergency Safe" "Settings avoids the oversized emergency card."
require_pattern "CampusLock/Features/LockView.swift" "CampusScreen \\{" "Lock ready/unlocked states use the shared shell."

echo "== UI regression tests =="
require_pattern "CampusLockUITests/CampusLockUITests.swift" "testOnboardingRequiresPermissionsThenZoneBeforeHome" "Setup and zone onboarding regression test exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "testAttendanceConfirmEnterHallPassAndExitFlow" "Attendance, hall pass, and exit confirmation test exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "home\\.settings" "Home settings gear assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "continue should stay disabled" "Disabled continue assertion exists."
reject_pattern "CampusLockUITests/CampusLockUITests.swift" "assertFooterTabsStayReachable" "UI tests no longer depend on footer tabs."
reject_pattern "CampusLockUITests/CampusLockUITests.swift" "assertActionSitsAboveFooter" "UI tests no longer reserve footer space."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "footer\\.menu" "Footer absence assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "should not be cropped" "Crop guard assertions exist."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "settings\\.zone" "Settings geofence assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "tab\\.stats" "Stats tab removal assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "tab\\.apps" "Settings tab removal assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "insights\\.prepareCSV" "Stats export removal assertion exists."

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

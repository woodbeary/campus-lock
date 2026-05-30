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

echo "== Native tab footer =="
require_pattern "CampusLock/Features/RootView.swift" "TabView\\(selection:" "Root uses native TabView selection."
require_pattern "CampusLock/Features/RootView.swift" "toolbarBackground\\(\\.visible, for: \\.tabBar\\)" "Tab footer is forced visible."
require_pattern "CampusLock/App/CampusLockApp.swift" "UITabBarAppearance" "Native tab bar appearance is configured."

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
require_pattern "CampusLockUITests/CampusLockUITests.swift" "testSetupScreenKeepsFooterAndFixedAction" "Setup footer/action regression test exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "assertFooterTabsStayReachable" "Footer reachability assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "assertActionSitsAboveFooter" "Fixed action placement assertion exists."
require_pattern "CampusLockUITests/CampusLockUITests.swift" "should not be cropped" "Crop guard assertions exist."

if (( failures > 0 )); then
  echo "UI layout verification failed with ${failures} issue(s)."
  exit 1
fi

echo "UI layout verification passed."

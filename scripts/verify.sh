#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

minimum_verify_free_gb="${MINIMUM_VERIFY_FREE_GB:-1}"

echo "== Verify disk space =="
free_kb="$(df -Pk . | awk 'NR==2 {print $4}')"
free_gb="$((free_kb / 1024 / 1024))"
if (( free_gb < minimum_verify_free_gb )); then
  echo "Free disk is ${free_gb} GiB; need at least ${minimum_verify_free_gb} GiB for local verification."
  echo "Run ./scripts/disk-unblock-audit.sh for read-only cleanup candidates."
  exit 1
fi
echo "Free disk: ${free_gb} GiB"

echo "== Swift package tests with coverage =="
./scripts/test-coverage.sh

echo "== JavaScript/TypeScript gates =="
js_gate_files="$(
  find . \
    \( -name package.json -o -name tsconfig.json -o -name 'jest.config.*' \) \
    -not -path './.git/*' \
    -not -path './.build/*' \
    -not -path './build/*' \
    -not -path './node_modules/*' \
    -print
)"

if [[ -z "$js_gate_files" ]]; then
  echo "No JavaScript or TypeScript project detected; Jest and noEmit are not applicable."
else
  echo "$js_gate_files"

  while IFS= read -r package_json; do
    package_dir="$(dirname "$package_json")"
    has_test_script="$(
      python3 - "$package_json" <<'PY'
import json
import sys

with open(sys.argv[1]) as handle:
    package = json.load(handle)

print("yes" if package.get("scripts", {}).get("test") else "no")
PY
    )"

    if [[ "$has_test_script" == "yes" ]]; then
      (cd "$package_dir" && pnpm test)
    elif find "$package_dir" -maxdepth 1 -name 'jest.config.*' | grep -q .; then
      (cd "$package_dir" && pnpm exec jest)
    else
      echo "No Jest test script/config in ${package_dir}; skipping Jest."
    fi
  done < <(echo "$js_gate_files" | grep '/package.json$' || true)

  while IFS= read -r tsconfig; do
    ts_dir="$(dirname "$tsconfig")"
    (cd "$ts_dir" && pnpm exec tsc --noEmit -p "$(basename "$tsconfig")")
  done < <(echo "$js_gate_files" | grep '/tsconfig.json$' || true)
fi

echo "== UI layout guard =="
./scripts/verify-ui-layout.sh

echo "== Release tooling lint =="
./scripts/verify-release-tooling.sh

echo "== Generate Xcode project =="
xcodegen generate

echo "== iOS SDK typecheck =="
./scripts/typecheck-ios.sh

iphoneos_sdk="${IPHONEOS_SDK:-iphoneos$(xcrun --sdk iphoneos --show-sdk-version)}"

echo "== iPhoneOS app build =="
xcodebuild \
  -project CampusLock.xcodeproj \
  -target CampusLock \
  -configuration Debug \
  -sdk "$iphoneos_sdk" \
  -arch arm64 \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_ON_DEMAND_RESOURCES=NO \
  build

echo "== iPhoneOS unit test bundle build =="
xcodebuild \
  -project CampusLock.xcodeproj \
  -target CampusLockTests \
  -configuration Debug \
  -sdk "$iphoneos_sdk" \
  -arch arm64 \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_ON_DEMAND_RESOURCES=NO \
  ENABLE_TESTABILITY=YES \
  SWIFT_OPTIMIZATION_LEVEL=-Onone \
  build

echo "== iPhoneOS UI test bundle build =="
xcodebuild \
  -project CampusLock.xcodeproj \
  -target CampusLockUITests \
  -configuration Debug \
  -sdk "$iphoneos_sdk" \
  -arch arm64 \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_ON_DEMAND_RESOURCES=NO \
  ENABLE_TESTABILITY=YES \
  SWIFT_OPTIMIZATION_LEVEL=-Onone \
  build

if xcodebuild -project CampusLock.xcodeproj -scheme CampusLock -showdestinations 2>/dev/null \
  | awk '/Available destinations/{available=1; next} /Ineligible destinations/{available=0} available && /platform:iOS/{found=1} END{exit found ? 0 : 1}'; then
  echo "== iOS Debug build =="
  xcodebuild \
    -project CampusLock.xcodeproj \
    -scheme CampusLock \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    build

  echo "== iOS test build =="
  xcodebuild \
    -project CampusLock.xcodeproj \
    -scheme CampusLock \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    build-for-testing
else
  echo "== iOS Xcode build skipped =="
  echo "No eligible iOS destination is installed in this Xcode. Open Xcode > Settings > Components and install the iOS platform, then rerun the build/archive command."
fi

echo "== Done =="

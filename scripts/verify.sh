#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Swift package tests =="
swift test

echo "== Generate Xcode project =="
xcodegen generate

echo "== iOS SDK typecheck =="
./scripts/typecheck-ios.sh

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

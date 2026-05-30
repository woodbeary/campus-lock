#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Swift package tests =="
swift test

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

#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
module_dir="build/typecheck"

rm -rf "$module_dir"
mkdir -p "$module_dir"

xcrun swiftc \
  -emit-module \
  -module-name CampusLockCore \
  -target arm64-apple-ios18.0 \
  -sdk "$sdk" \
  -parse-as-library \
  Sources/CampusLockCore/*.swift \
  -emit-module-path "$module_dir/CampusLockCore.swiftmodule"

xcrun swiftc \
  -typecheck \
  -target arm64-apple-ios18.0 \
  -sdk "$sdk" \
  -I "$module_dir" \
  -parse-as-library \
  $(find CampusLock -name '*.swift' | sort)

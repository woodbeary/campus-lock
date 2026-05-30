#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

scheme="${SCHEME:-CampusLock}"
configuration="${CONFIGURATION:-Debug}"
development_team="${DEVELOPMENT_TEAM:-YOUR_TEAM_ID}"
destination="${E2E_DESTINATION:-}"

xcodegen generate

if [[ -z "$destination" ]]; then
  destinations="$(xcodebuild -project CampusLock.xcodeproj -scheme "$scheme" -showdestinations 2>&1 || true)"
  destination_id="$(awk '
    /Available destinations/ { available=1; next }
    /Ineligible destinations/ { available=0 }
    available && /platform:iOS/ && $0 !~ /DVTiPhonePlaceholder/ {
      if (match($0, /id:[^,}]+/)) {
        value = substr($0, RSTART + 3, RLENGTH - 3)
        gsub(/^ +| +$/, "", value)
        print value
        exit
      }
    }
  ' <<<"$destinations")"

  if [[ -z "$destination_id" ]]; then
    echo "No eligible concrete iOS destination is available for UI test execution."
    echo "Set E2E_DESTINATION='id=<device-or-simulator-id>' after Xcode shows an eligible destination."
    echo
    echo "$destinations"
    exit 66
  fi

  destination="id=${destination_id}"
fi

xcodebuild \
  -project CampusLock.xcodeproj \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -destination "$destination" \
  -only-testing:CampusLockUITests \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$development_team" \
  ENABLE_ON_DEMAND_RESOURCES=NO \
  test

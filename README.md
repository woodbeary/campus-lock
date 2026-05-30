# Campus Lock

Native SwiftUI MVP for a classroom focus lock and attendance flow.

## What works

- Setup gate for Screen Time and Location permissions.
- App/category selection with Apple `FamilyControls` picker when available.
- Location radius builder with a 50-500 meter slider.
- One-tap class entry that marks attendance and applies Screen Time shields.
- Manual unlock and automatic geofence checkout path.
- Local attendance persistence and CSV export.
- Native SwiftUI UI with iOS 26 Liquid Glass guarded by availability fallback.

## Verify

```sh
./scripts/verify.sh
```

## Generate project

```sh
xcodegen generate
open CampusLock.xcodeproj
```

## Build to iPhone

1. Open `CampusLock.xcodeproj`.
2. Select the `CampusLock` scheme.
3. Select the test iPhone.
4. Confirm Signing & Capabilities uses team `YOUR_TEAM_ID`.
5. Build and run.

## Ad hoc archive

```sh
./scripts/archive-adhoc.sh
```

Important: real app blocking requires Apple approval for the Family Controls entitlement on the signing team. The app is wired to the real APIs and does not pretend entitlement approval is automatic.

If `xcodebuild` reports that iOS is not installed, open Xcode > Settings > Components and install the matching iOS platform/runtime. The repo also includes `./scripts/typecheck-ios.sh`, which verifies the SwiftUI app against the iPhoneOS SDK without requiring Simulator.

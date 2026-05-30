# Campus Lock

Native SwiftUI MVP for classroom focus locking and attendance.

## What is implemented

- Setup gate for Screen Time and Location permissions.
- Apple `FamilyControls` picker for user-selected apps/categories.
- Local persistence for the selected Screen Time tokens.
- `ManagedSettingsStore` shields for selected apps/categories.
- Custom Screen Time shield configuration and action extensions.
- Native MapKit classroom radius with a 50-500 meter slider and Always Location setup gate.
- Tap-in attendance that starts focus and tap-out/manual unlock that ends it.
- Geofence exit path that unlocks when the user leaves the radius.
- Local JSON persistence, attendance history, insights, and CSV export.
- Native SwiftUI interface with iOS 26 Liquid Glass where available and fallback materials elsewhere.

## Verify locally

```sh
./scripts/verify.sh
```

This runs Swift package tests, regenerates the Xcode project, typechecks against the installed iPhoneOS SDK, and performs an unsigned iPhoneOS build of the app plus shield extensions.
It also compiles the iOS unit-test bundle and UI-test runner against the iPhoneOS SDK even when no simulator/device destination is eligible.

## Generate project

```sh
xcodegen generate
open CampusLock.xcodeproj
```

## Build an installable iPhone release

```sh
./scripts/archive-adhoc.sh
```

For a registered-device build that works without Simulator and without archive export:

```sh
./scripts/build-development-ipa.sh
```

That writes `build/export/CampusLock-development.ipa` using the local Apple Development profiles. To install directly on Jacob's registered iPhone, keep the phone awake/unlocked and run:

```sh
./scripts/install-development-build.sh
```

To check release prerequisites without starting an archive:

```sh
./scripts/release-preflight.sh
```

The script expects the local Mac/Xcode account to be release-ready:

- Xcode is signed in to Apple Developer team `YOUR_TEAM_ID`.
- Provisioning profiles can be created or downloaded for the app and shield extensions.
- The matching iOS platform for the connected iPhone is installed in Xcode Components.
- Family Controls is approved for the main app and both shield extension bundle IDs.

Current local audit details are in `READINESS_AUDIT.md`.

The archive release is considered complete when `build/export` contains an installable `.ipa` produced by `./scripts/archive-adhoc.sh`. The development-signed fallback is considered ready for registered devices when `build/export/CampusLock-development.ipa` exists and `./scripts/install-development-build.sh` installs it successfully.

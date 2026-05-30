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

This runs Swift package tests, checks JavaScript/TypeScript gates when a `package.json`, `jest.config.*`, or `tsconfig.json` exists, regenerates the Xcode project, typechecks against the installed iPhoneOS SDK, and performs an unsigned iPhoneOS build of the app plus shield extensions.
It also compiles the iOS unit-test bundle and UI-test runner against the iPhoneOS SDK even when no simulator/device destination is eligible.
Swift package coverage is enforced at 80% minimum line coverage for the core domain target.

To run the full release-readiness gate, including E2E execution and ad hoc export checks:

```sh
./scripts/verify-release-ready.sh
```

This command is intentionally stricter than `./scripts/verify.sh`; it fails until UI tests execute on an eligible iOS destination and `./scripts/archive-adhoc.sh` produces a shareable archive export.

To run the read-only App Store Connect signing readiness check:

```sh
./scripts/asc-release-readiness.sh
```

This verifies the three bundle IDs, Family Controls capabilities, distribution certificate, and registered iPhone without creating profiles.

To verify the latest packaged registered-device IPA:

```sh
./scripts/verify-ipa-artifact.sh
```

This checks the app plus both shield extension embedded profiles, Family Controls entitlements, registered device inclusion, code signatures, and SHA-256 hash.

To create the three ad hoc profiles after Team Admin credentials are available:

```sh
CONFIRM_CREATE_ADHOC_PROFILES=1 ./scripts/create-adhoc-profiles.sh
```

This command is guarded because it mutates Apple Developer state.

To generate deterministic manual export options from installed Family Controls ad hoc profiles:

```sh
./scripts/generate-export-options.sh
```

`./scripts/archive-adhoc.sh` runs this automatically unless `EXPORT_OPTIONS` is set.

To inspect disk space blockers without deleting anything:

```sh
./scripts/disk-unblock-audit.sh
```

To smoke-test the latest installed registered-device build:

```sh
./scripts/smoke-device-launch.sh
```

This requires the connected iPhone to be awake and unlocked.

To execute the iOS UI/E2E tests on an eligible device or simulator:

```sh
./scripts/run-ui-tests.sh
```

If Xcode cannot auto-detect a concrete eligible destination, pass one explicitly:

```sh
E2E_DESTINATION='id=<device-or-simulator-id>' ./scripts/run-ui-tests.sh
```

To run only the Swift package coverage gate:

```sh
./scripts/test-coverage.sh
```

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
- Family Controls Development and Distribution are approved for the main app and both shield extension bundle IDs.

Current local audit details are in `READINESS_AUDIT.md`, `COMPLETION_AUDIT.md`, and the machine-readable `RELEASE_BLOCKERS.json`.

The archive release is considered complete when `build/export` contains an installable `.ipa` produced by `./scripts/archive-adhoc.sh`. The development-signed fallback is considered ready for registered devices when `build/export/CampusLock-development.ipa` exists, `./scripts/install-development-build.sh` installs it successfully, and the installed app launch/visual smoke test passes on the unlocked phone.

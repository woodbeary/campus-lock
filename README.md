# Campus Lock

Native SwiftUI MVP for classroom focus locking and attendance.

## What is implemented

- Setup gate for Screen Time and Location permissions.
- Onboarding-first flow; Home appears only after required permissions and zone setup.
- One-screen Home with a glass settings gear instead of a bottom Settings tab.
- Recommended focus preset that shields every app and website category Apple allows without forcing manual app selection.
- Apple `FamilyControls` picker for user-selected apps/categories.
- Local persistence for the selected Screen Time tokens.
- `ManagedSettingsStore` shields for selected apps/categories.
- Custom Screen Time shield configuration and action extensions.
- Native MapKit classroom radius around the current location with a 50-500 meter slider and Always Location setup gate.
- Tap-in attendance that starts focus and tap-out/manual unlock that ends it.
- Geofence exit path that unlocks when the user leaves the radius.
- Local JSON persistence, attendance history, and compact settings-based insights.
- Native SwiftUI interface with iOS 26 Liquid Glass where available and fallback materials elsewhere.

## Verify locally

```sh
./scripts/verify.sh
```

This runs Swift package tests, checks JavaScript/TypeScript gates when a `package.json`, `jest.config.*`, or `tsconfig.json` exists, lints release scripts/plists/manifests, regenerates the Xcode project, typechecks against the installed iPhoneOS SDK, and performs an unsigned iPhoneOS build of the app plus shield extensions.
It also compiles the iOS unit-test bundle and UI-test runner against the iPhoneOS SDK even when no simulator/device destination is eligible.
It includes a UI layout guard for the one-screen Home, glass settings gear, bottom action dock, shared screen shell, and no `GeometryReader` crowding regressions.
It fails before heavy builds if free disk is below `MINIMUM_VERIFY_FREE_GB`, which defaults to `1`.
Swift package coverage is enforced at 80% minimum line coverage for the core domain target.

To run only the UI layout guard:

```sh
./scripts/verify-ui-layout.sh
```

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
For an exported ad hoc IPA, require distribution-style signing explicitly:

```sh
IPA_PATH="$(cat build/export/latest-adhoc-ipa.path)" EXPECTED_SIGNING=ad-hoc ./scripts/verify-ipa-artifact.sh
```

To create, download, install, and wire the three ad hoc profiles after Team Admin credentials are available:

```sh
CONFIRM_CREATE_ADHOC_PROFILES=1 ./scripts/create-adhoc-profiles.sh
```

This command is guarded because it mutates Apple Developer state. It installs the created profiles locally and regenerates export options unless `INSTALL_CREATED_PROFILES=0` or `GENERATE_EXPORT_OPTIONS=0` is set.

To safely audit whether matching remote ad hoc profiles already exist without
printing provisioning profile contents:

```sh
./scripts/audit-adhoc-profiles.sh
```

If that audit passes, install the matching downloaded profiles locally:

```sh
INSTALL_MATCHING_PROFILES=1 ./scripts/audit-adhoc-profiles.sh
```

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

If Xcode cannot run a normal archive destination but Team Admin ad hoc profiles are already installed, this fallback wraps the built iPhone app in an archive and runs export directly:

```sh
./scripts/archive-adhoc-from-built-app.sh
```

The fallback still runs signing/profile/disk checks; it skips only the Xcode destination check that normal archives require.

For a registered-device build that works without Simulator and without archive export:

```sh
./scripts/build-development-ipa.sh
```

That writes `build/export/CampusLock-development.ipa`, copies the same IPA to `~/Downloads/CampusLock-development.ipa`, and uses the local Apple Development profiles. To install directly on Jacob's registered iPhone, keep the phone awake/unlocked and run:

```sh
./scripts/install-development-build.sh
```

For a quick registered-device launch smoke after install:

```sh
./scripts/smoke-device-launch.sh
```

Both device scripts write `devicectl` logs under `build/export` and print specific next steps for locked-phone, CoreDevice timeout, and interrupted-connection failures.

To check release prerequisites without starting an archive:

```sh
./scripts/release-preflight.sh
```

If disk is the only immediate blocker, inspect guarded cleanup options without deleting anything:

```sh
./scripts/release-space-cleanup.sh
```

Applying cleanup requires explicit flags such as `CLEAN_COLIMA=1 CONFIRM_RELEASE_CLEANUP=1 ./scripts/release-space-cleanup.sh`.

The script expects the local Mac/Xcode account to be release-ready:

- Xcode is signed in to Apple Developer team `YOUR_TEAM_ID`.
- Provisioning profiles can be created or downloaded for the app and shield extensions.
- The matching iOS platform for the connected iPhone is installed in Xcode Components.
- Family Controls Development and Distribution are approved for the main app and both shield extension bundle IDs.

Current local audit details are in `READINESS_AUDIT.md`, `COMPLETION_AUDIT.md`, and the machine-readable `RELEASE_BLOCKERS.json`.

Current external blockers on this Mac:

- Xcode is `26.1` with iPhoneOS `26.1`; the test iPhone is iOS `26.4.2`, so Xcode marks the phone ineligible for E2E tests and archive destinations.
- `xcodebuild -downloadPlatform iOS -buildVersion 26.4.2` and `26.4` report that those platforms are not available through this Xcode install.
- The current App Store Connect credential passes read-only bundle/cert/device checks but cannot create provisioning profiles; `./scripts/create-adhoc-profiles.sh` needs Team Admin credentials.
- `./scripts/audit-adhoc-profiles.sh` finds zero remote `IOS_APP_ADHOC` candidates for the three Campus Lock bundle IDs, so there are no ready remote profiles to download/install with the current account.
- Installed release-testing/ad hoc profiles for the app and both shield extensions do not include the Family Controls Distribution entitlement.

The archive release is considered complete when `build/export` contains an installable `.ipa` produced by `./scripts/archive-adhoc.sh` or `./scripts/archive-adhoc-from-built-app.sh`. The development-signed fallback is considered ready for registered devices when `build/export/CampusLock-development.ipa` exists, `./scripts/install-development-build.sh` installs it successfully, and the installed app launch/visual smoke test passes on the unlocked phone.

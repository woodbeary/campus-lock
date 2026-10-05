# Campus Lock

**Tap your phone on the classroom door and your distracting apps lock while attendance is marked. Walk out of the room's radius and they unlock. It's a native SwiftUI app built on Apple's Screen Time APIs. In one day, May 30, 2026, it went from plan to running on an iPhone.**

Built by [Jacob Lopez](https://jacob.com.ai).

<table>
  <tr>
    <td width="33%"><img src="design/screens-final/04-ready.png" alt="Ready screen with a Tap in button"></td>
    <td width="33%"><img src="design/screens-final/05-focus-active.png" alt="Locked screen with focus and passing-period timers"></td>
    <td width="33%"><img src="design/screens-final/09-shield.png" alt="The custom shield shown when a locked app is opened"></td>
  </tr>
</table>

<sub>These are design mockups made before the build, rendered by <a href="design/generate_final_mockups.py"><code>design/generate_final_mockups.py</code></a>. They aren't screenshots of the app.</sub>

## What it does

- **Real Screen Time shields.** Students pick apps, categories, and websites in Apple's `FamilyControls` picker. A named `ManagedSettingsStore` then shields them, and two extensions replace Apple's default blocked-app screen and handle its buttons. See [`ScreenTimeController.swift`](CampusLock/Services/ScreenTimeController.swift), [`CampusLockShieldConfiguration`](CampusLockShieldConfiguration), and [`CampusLockShieldAction`](CampusLockShieldAction).
- **NFC tap-in.** Core NFC reads NDEF and ISO 14443, 15693, and 18092 tags. A tap starts focus and marks attendance in the same step. There's a delayed manual fallback for demos. See [`NFCSessionController.swift`](CampusLock/Services/NFCSessionController.swift).
- **A classroom geofence.** You set a 50 to 500 meter radius on a map, around your current location or a school you search for. Leaving that region ends the session and clears the shields. See [`LocationController.swift`](CampusLock/Services/LocationController.swift) and [`SchoolSearchService.swift`](CampusLock/Services/SchoolSearchService.swift).
- **A tested core.** Every state transition runs through a reducer in a Swift package, [`CampusLockCore`](Sources/CampusLockCore). The package also handles session timing, attendance analytics, and CSV export. It has 25 Swift Testing cases, and [`scripts/test-coverage.sh`](scripts/test-coverage.sh) enforces an 80% line-coverage floor.
- **Liquid Glass on iOS 26**, with standard materials on earlier versions.
- **One verification command.** [`scripts/verify.sh`](scripts/verify.sh) runs the package tests and a UI layout guard. It also typechecks against the iOS SDK and builds the app and both extensions for an iPhone, unsigned.

## Run it

You need Xcode 26 and a physical iPhone, because Screen Time shields and NFC don't run in the Simulator. You also need the Family Controls capability on your Apple team. Development builds work right away; distribution needs Apple's approval.

```bash
brew install xcodegen
xcodegen generate            # set DEVELOPMENT_TEAM in project.yml first
open CampusLock.xcodeproj
swift test                   # core package tests, on macOS
./scripts/verify.sh          # the full local gate
```

## What's in this repo

This is the original commit history, from May 30 to Aug 14, 2026. Before publishing, I removed the release-signing scripts and agent-written audit logs, because they contained device and team identifiers. Apple team IDs are replaced with placeholders. The [MVP plan](CAMPUS_LOCK_MVP_PLAN.md) is the one I wrote before building.

## More

The project I'm proudest of is [TXT CLAW → Rotary](https://github.com/woodbeary/rotary): always-on agents you can text, shipped in February 2026.

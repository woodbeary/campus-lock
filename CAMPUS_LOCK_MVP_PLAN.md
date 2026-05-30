# Campus Lock Native MVP Plan

Last updated: 2026-05-30

## Objective

Build a native Swift iPhone MVP that proves the core promise:

- The user chooses which apps/categories/websites should be unavailable during focus time.
- The app requests the correct Apple permissions before use.
- The user draws a circular focus zone around their current location.
- When focus is on and the user is inside the zone, selected apps are shielded through Apple Screen Time APIs.
- When the user leaves the zone or intentionally turns focus off, shields are cleared.
- Attendance is captured in the same flow through manual class enter/exit taps until NFC hardware exists.
- The founder can demo the full experience from one phone without pretending to be separate admin/student users.

## Hard Product Rules

- One app, one user, one screen-first experience.
- Native SwiftUI only; no Expo, React Native, web dashboard, Supabase, or simulator dependency.
- Real Apple Screen Time shielding; no fake lock screen as the primary proof.
- Minimalist interface: icons, circles, chips, small numbers, short labels.
- No paragraphs in the app UI after setup.
- Event-only location logging; no route tracking or “where the student walked” map in MVP.
- Everything works locally on the phone first.
- TestFlight is the pilot target, but development builds on the test iPhone immediately while Family Controls distribution entitlement is pending.

## Technical Stack

- Language: Swift.
- UI: SwiftUI.
- Map: MapKit.
- Location: Core Location.
- Restrictions: FamilyControls, ManagedSettings, ManagedSettingsUI.
- Shield UI: Shield Configuration extension.
- Shield actions: Shield Action extension.
- Persistence: SwiftData for product data; shared App Group UserDefaults or file storage for Screen Time token state.
- Distribution path: development install to the test iPhone first, then TestFlight after entitlement/signing is clean.
- Minimum OS: iOS 17.
- Preferred polish: iOS 26 Liquid Glass using native APIs, gated with `#available(iOS 26, *)`.

## Apple API Reality

### Screen Time

Use the real Screen Time framework path:

- `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
- `FamilyActivityPicker`
- `FamilyActivitySelection`
- `ManagedSettingsStore`
- `ManagedSettingsStore.shield.applications`
- `ManagedSettingsStore.shield.applicationCategories`
- `ManagedSettingsStore.shield.webDomains`
- `ShieldConfigurationExtension`
- `ShieldActionExtension`

Important constraints:

- App selections are privacy-preserving opaque tokens.
- The app cannot inspect exact selected app names after selection.
- The app can shield selected apps/categories/websites, not literally lock the entire phone.
- Screen Time distribution through TestFlight/App Store requires Apple entitlement approval.
- The MVP should still be built and tested on-device with development signing while approval is pending.

### Geofence

Use Core Location for the focus zone:

- Ask for When In Use first only if needed for current location.
- Require Always authorization before enabling automatic enter/exit behavior.
- Use `CLMonitor` and `CLCircularGeographicCondition` on iOS 17+.
- Maintain an app foreground fallback that checks current distance from center on app launch/resume.
- Store the zone as center latitude, center longitude, radius meters, enabled flag, and last known state.

### Notifications

Request notification permission during setup, but do not block app use if denied.

Use notifications for:

- Entered focus zone.
- Apps shielded.
- Left focus zone.
- Passing period countdown warning.
- Class exit reminder if the user forgets to exit.

## App Targets

### Main App

Responsibilities:

- Setup checklist.
- App/category picker.
- Location permission flow.
- Map/radius editor.
- Focus state machine.
- Attendance state machine.
- Local insights.
- Export/share sheet.

### Shield Configuration Extension

Responsibilities:

- Display the system shield for blocked apps.
- Keep shield copy extremely short.
- Use icon-first lock language.
- Provide one primary action that sends user back to Campus Lock.

Preferred shield content:

- Title: `Focus`
- Subtitle: `Return to class`
- Primary button: `Open`

### Shield Action Extension

Responsibilities:

- Handle shield action.
- Open Campus Lock using a custom URL scheme.
- Do not silently unlock from the shield.
- Keep unlock decisions inside the main app so events are logged.

## Data Model

### FocusZone

Fields:

- `id`
- `name`
- `centerLatitude`
- `centerLongitude`
- `radiusMeters`
- `isEnabled`
- `lastKnownInside`
- `createdAt`
- `updatedAt`

Default:

- One zone named `Campus`.
- Center is current location.
- Radius starts at 200m.
- Slider range is 100m to 500m.

### FocusSession

Fields:

- `id`
- `zoneId`
- `startedAt`
- `endedAt`
- `startReason`
- `endReason`
- `insideAtStart`
- `manualUnlockCount`

Reasons:

- `zoneEntered`
- `manualOn`
- `classEntered`
- `zoneExited`
- `manualOff`
- `manualUnlock`
- `permissionLost`
- `selectionMissing`

### FocusEvent

Fields:

- `id`
- `timestamp`
- `type`
- `zoneId`
- `classId`
- `detail`

Types:

- `setupCompleted`
- `appsSelected`
- `zoneCreated`
- `zoneEnabled`
- `zoneDisabled`
- `zoneEntered`
- `zoneExited`
- `shieldApplied`
- `shieldCleared`
- `manualUnlock`
- `permissionDenied`
- `permissionRestored`
- `attendanceEnter`
- `attendanceExit`
- `passingStarted`
- `passingEnded`
- `exportCreated`

### ClassItem

Fields:

- `id`
- `icon`
- `name`
- `room`
- `sortOrder`
- `expectedStartTime`
- `expectedEndTime`
- `isArchived`

Defaults:

- Create three sample classes for the founder demo.
- Allow quick edit, add, reorder, and archive.

### AttendanceRecord

Fields:

- `id`
- `classId`
- `enteredAt`
- `exitedAt`
- `entryFocusState`
- `exitFocusState`
- `passingSecondsFromPreviousClass`
- `manualNote`

Computed:

- Present if `enteredAt` exists.
- Complete if both enter and exit exist.
- Missed exit if a new class starts while previous class is still open.

### ScreenTimeSelectionStore

Storage:

- Persist `FamilyActivitySelection` in App Group storage as encoded data.
- Refresh/validate before applying shields.

State:

- `hasSelection`
- `applicationTokenCount`
- `categoryTokenCount`
- `webDomainTokenCount`
- `updatedAt`

Display:

- Do not show app names.
- Show counts only: `12 apps`, `2 groups`, `3 sites`.

## State Machine

### Setup State

The app is unusable until these are complete:

1. Screen Time authorization approved.
2. At least one app/category/site selected.
3. Location permission suitable for current location.
4. Always Location approved before automatic zone lock can be enabled.
5. A valid zone exists.

Setup screen style:

- Vertical checklist.
- Icon per requirement.
- Green check when complete.
- One short action button per missing requirement.
- No explanatory paragraphs.

Checklist icons:

- Screen Time: `hourglass`
- Apps: `app.badge.checkmark`
- Location: `location.circle`
- Zone: `scope`
- Notifications: `bell.badge`

### Focus State

States:

- `notReady`
- `readyOff`
- `outsideZone`
- `insideUnlocked`
- `insideShielded`
- `manualOverride`
- `permissionBlocked`

Rules:

- `notReady`: setup incomplete; no shields.
- `readyOff`: setup complete; zone not enabled; no shields.
- `outsideZone`: zone enabled and user outside; no shields.
- `insideUnlocked`: user inside zone but focus not manually turned on yet; show Turn On.
- `insideShielded`: user inside zone and focus active; apply shields.
- `manualOverride`: user intentionally unlocked while inside; shields cleared; event logged.
- `permissionBlocked`: required permission revoked; shields cleared and setup repair shown.

### Shield Apply Rules

Apply shields when:

- Setup complete.
- Zone enabled.
- Focus active.
- User is inside zone.
- Selection is non-empty.

Clear shields when:

- User exits zone.
- User manually turns focus off.
- User manually unlocks.
- Selection becomes empty.
- Screen Time authorization is revoked.
- Location permission needed for the active mode is revoked.

### Manual Unlock Rule

Manual unlock should be deliberate:

- Long press primary unlock control for 2 seconds.
- Show one compact confirmation sheet.
- Log `manualUnlock`.
- Clear shields immediately.
- Keep zone enabled.
- Offer `Resume` button if still inside the zone.

No guilt copy. No long warning.

## User Experience

### First Launch

Screen layout:

- Centered logo glyph.
- Five setup rows.
- One primary action at bottom.

Rows:

- `Screen Time`
- `Apps`
- `Location`
- `Zone`
- `Alerts`

Each row:

- Symbol.
- One-word label.
- Status chip.
- Tap opens exact required system/app flow.

### App Selection

Use `FamilyActivityPicker`.

Flow:

- Tap Apps row.
- Present picker.
- User selects apps/categories/websites to disable during focus.
- Save selection.
- Return to setup.
- Show counts only.

### Zone Builder

Screen elements:

- Full-screen MapKit map.
- Current location dot.
- Circular overlay.
- Bottom glass control pod.

Controls:

- Radius slider.
- `100m`, current radius, `500m`.
- Center button: current location icon.
- Confirm button: checkmark.

Default:

- Use current location.
- Radius 200m.

Liquid Glass:

- Bottom pod uses glass surface.
- Confirm and current-location buttons use glass button styles.
- Slider stays native.

### Main Screen After Setup

One-screen hierarchy:

- Top compact state ring.
- Middle attendance/action card.
- Bottom insights strip.

No tab bar for MVP unless needed.

Primary ring:

- Large circular state.
- Icon in center.
- Ring color by state.
- Tiny label below.

State icons:

- Outside: `figure.walk.circle`
- Inside ready: `location.fill`
- Shielded: `lock.shield`
- Override: `lock.open`
- Blocked: `exclamationmark.triangle`

Primary action:

- Outside: none or `On`
- Inside unlocked: `On`
- Shielded: long-press `Unlock`
- Override: `Resume`
- Off: `Start`

### Attendance Card

Default:

- Shows next/open class.
- Big icon.
- Room chip.
- Enter/Exit button.
- Passing timer if between classes.

Class row copy:

- `Math`
- `Room 204`
- `Enter`
- `Exit`
- `Passing 04:12`

Behavior:

- Tap Enter marks attendance.
- Enter also turns focus on if setup complete.
- Tap Exit closes attendance record.
- Exit does not automatically unlock if still inside zone unless user chooses Unlock.
- Passing timer starts after Exit and stops on next Enter.

### Insights Strip

Local founder/admin demo metrics:

- Attendance %
- Focus minutes
- Unlocks
- Avg passing
- Missed exits

Icons:

- Attendance: `checkmark.seal`
- Focus: `timer`
- Unlocks: `lock.open`
- Passing: `figure.walk`
- Missed: `exclamationmark.circle`

Tap insights opens a compact sheet with event timeline and export.

### Event Timeline

Rows:

- Icon.
- Time.
- Short event label.
- Optional class/zone chip.

Examples:

- `08:01 Enter Math`
- `08:01 Focus On`
- `08:52 Exit Math`
- `08:56 Enter Science`
- `09:44 Unlock`
- `15:02 Zone Exit`

## Visual Direction

### Style

- Minimal, spatial, calm.
- Large circles.
- No heavy titles.
- No marketing copy.
- Use system icons to convey action.
- Use high contrast and large tap targets.
- Prefer motion and state over text.

### Color

Base:

- Background: system grouped background.
- Foreground: primary text.
- Secondary: tertiary text.

States:

- Ready/off: gray.
- Outside/free: blue.
- Inside/focus active: green.
- Shielded: teal.
- Override/unlocked inside: amber.
- Permission blocked: red.

### Liquid Glass

Use native APIs:

- `.glassEffect(...)`
- `GlassEffectContainer`
- `.buttonStyle(.glass)`
- `.buttonStyle(.glassProminent)`

Fallback:

- `.ultraThinMaterial`
- rounded rectangles.

Apply glass only to:

- Bottom map controls.
- State/action capsule.
- Attendance card.
- Insights sheet.

Avoid:

- Custom blur stacks.
- Overlapping glass surfaces everywhere.
- Long text inside glass.

## File/Module Plan

Suggested structure:

- `CampusLockApp.swift`
- `Models/`
- `Services/`
- `Features/Setup/`
- `Features/Zone/`
- `Features/Focus/`
- `Features/Attendance/`
- `Features/Insights/`
- `Extensions/ShieldConfiguration/`
- `Extensions/ShieldAction/`

Key services:

- `ScreenTimeAuthorizationService`
- `ScreenTimeSelectionStore`
- `ShieldService`
- `LocationAuthorizationService`
- `ZoneMonitorService`
- `FocusCoordinator`
- `AttendanceService`
- `ExportService`

Keep services small and injectable.

## Service Responsibilities

### ScreenTimeAuthorizationService

- Observe `AuthorizationCenter.shared.authorizationStatus`.
- Request `.individual` authorization.
- Expose `approved`, `denied`, `notDetermined`.
- Emit setup repair actions if revoked.

### ScreenTimeSelectionStore

- Own `FamilyActivitySelection`.
- Present/save picker binding.
- Encode/decode selection to App Group storage.
- Provide counts for UI.
- Return selected tokens to `ShieldService`.

### ShieldService

- Own a named `ManagedSettingsStore`.
- Apply selected apps/categories/web domains.
- Clear all shield settings.
- Never apply empty shields.
- Log apply/clear through `FocusCoordinator`.

### LocationAuthorizationService

- Request When In Use and Always.
- Expose precise/reduced accuracy state.
- Expose repair actions.
- Do not allow automatic zone mode until Always is approved.

### ZoneMonitorService

- Create/update one circular monitor condition.
- Persist the zone.
- Emit enter/exit events.
- Check current location on app launch/resume.
- Debounce noisy location transitions.

### FocusCoordinator

- Own focus state machine.
- Decides when to call `ShieldService.apply`.
- Decides when to clear shields.
- Logs every meaningful transition.
- Handles manual unlock.
- Handles permission revocation.

### AttendanceService

- Create/update classes.
- Enter class.
- Exit class.
- Compute passing duration.
- Handle missed exit.
- Provide today’s attendance summary.

### ExportService

- Generate CSV and JSON.
- Include only event and attendance data.
- Exclude raw route history.
- Launch share sheet.

## Permission Copy

Use short, utilitarian copy only.

Screen Time:

- Label: `Screen Time`
- Body: `Choose apps to pause during focus.`

Location:

- Label: `Location`
- Body: `Auto-start focus inside your circle.`

Notifications:

- Label: `Alerts`
- Body: `Timers and reminders.`

NFC future:

- Label: `Tap In`
- Body: `Classroom tags later.`

## Acceptance Criteria

### Setup

- Fresh install opens setup.
- User cannot turn on focus without Screen Time authorization.
- User cannot turn on focus without a selected app/category/site.
- User cannot enable automatic zone mode without Always Location.
- If notifications are denied, app continues and marks Alerts as optional.

### App Selection

- App picker appears.
- Selection persists after app restart.
- UI shows counts.
- No selected app names are shown.

### Zone

- Map centers on current location.
- Circle overlay follows slider.
- Confirm saves the zone.
- Zone persists after restart.
- Current inside/outside state is computed after save.

### Focus

- Enable focus inside zone applies shields.
- Leaving zone clears shields.
- Re-entering zone reapplies shields if focus remains enabled.
- Manual Off clears shields.
- Manual Unlock inside zone clears shields and logs event.
- Resume reapplies shields when still inside zone.
- Revoking Screen Time authorization clears shields and shows repair state.

### Shield

- Selected test app shows Apple shield UI.
- Shield action opens Campus Lock.
- Shield action does not silently unlock.

### Attendance

- Enter class creates attendance record.
- Exit class closes attendance record.
- Passing timer starts after exit.
- Passing timer stops on next enter.
- Missing exit is detected when a new class is entered.
- Today’s attendance percentage updates correctly.

### Insights

- Focus minutes update.
- Manual unlock count updates.
- Average passing time updates.
- Timeline shows events in chronological order.
- Export includes attendance and focus events.

## Test Scenarios

### Device Build

- Build directly to the test iPhone.
- Use iPhone Mirroring for interaction checks.
- Avoid Simulator.
- Avoid SwiftUI previews if memory pressure is high.

### Happy Path

1. Install app.
2. Approve Screen Time.
3. Select one disposable app.
4. Approve location.
5. Build radius at current location.
6. Turn focus on.
7. Confirm selected app is shielded.
8. Walk/drive outside radius.
9. Confirm selected app works again.
10. Re-enter radius.
11. Confirm selected app is shielded again.

### Manual Unlock Path

1. Stand inside radius.
2. Turn focus on.
3. Long-press Unlock.
4. Confirm shields clear.
5. Confirm unlock event logged.
6. Tap Resume.
7. Confirm shields return.

### Attendance Path

1. Enter Math.
2. Confirm focus starts.
3. Exit Math.
4. Confirm passing timer starts.
5. Enter Science.
6. Confirm passing timer stops.
7. Confirm attendance and average passing update.

### Revocation Path

1. Approve Screen Time.
2. Apply shields.
3. Revoke Screen Time permission in Settings.
4. Reopen app.
5. Confirm shields clear.
6. Confirm setup repair state appears.

### Export Path

1. Complete at least two class sessions.
2. Trigger one manual unlock.
3. Export event history.
4. Confirm CSV/JSON contains timestamps, event types, classes, focus session IDs, and no route trace.

## TestFlight Path

Steps:

1. Create bundle ID under Jacob-owned Apple Developer account.
2. Enable Family Controls capability for main app and extensions.
3. Enable App Groups for main app and extensions.
4. Request Family Controls distribution entitlement from Apple.
5. Use development signing for local iPhone builds while entitlement is pending.
6. Archive only after signing profiles include Family Controls for distribution.
7. Upload internal TestFlight.
8. Validate on the test iPhone through TestFlight.

Blocker:

- If Apple has not approved distribution entitlement, TestFlight may not be able to run the Screen Time parts correctly.

Fallback:

- Continue local development builds.
- Do not ship a fake-lock TestFlight unless explicitly requested.

## Privacy and School Positioning

Do:

- Track attendance events.
- Track focus state transitions.
- Track zone enter/exit timestamps.
- Track unlock counts.
- Track passing-period durations.

Do not:

- Track raw walking routes.
- Show a Find My-style student movement map.
- Record app usage content.
- Record messages, browsing, notifications, or screen contents.
- Claim AB 3216 mandates this exact software feature set.

Sales-safe line:

- `Helps schools enforce phone-free policies while creating attendance and compliance evidence.`

AB 3216-safe line:

- `California schools must adopt a smartphone-use policy by July 1, 2026; this app is one possible enforcement and reporting tool.`

## Future NFC Path

MVP uses manual class tap.

Later NFC flow:

- Teacher places NFC tag near classroom entrance.
- Student opens app and taps Scan.
- Core NFC reads classroom tag.
- Attendance Enter is recorded.
- Focus starts or continues.
- Exit tap/tag closes class.

Future model addition:

- `ClassroomTag`
- `tagIdentifier`
- `classId`
- `room`
- `lastSeenAt`

Do not build NFC in this MVP unless hardware exists.

## Implementation Order

### Day 1

- Create Xcode project.
- Add main app target.
- Add Shield Configuration and Shield Action extensions.
- Add entitlements and App Group placeholders.
- Build empty app to the test iPhone.
- Add setup checklist shell.

### Day 2

- Add Screen Time authorization.
- Add FamilyActivityPicker.
- Persist selection.
- Add ShieldService.
- Prove selected app shields from a manual test button.

### Day 3

- Add MapKit zone builder.
- Add location permission flow.
- Add zone persistence.
- Add inside/outside detection.
- Connect zone state to shielding.

### Day 4

- Add focus state machine.
- Add manual On/Off/Unlock/Resume.
- Add shield extension copy/action.
- Add event logging.

### Day 5

- Add class model.
- Add attendance Enter/Exit.
- Add passing timer.
- Add insights strip.
- Add event timeline.

### Day 6

- Add export.
- Polish Liquid Glass surfaces.
- Harden permission revocation.
- Run full on-device acceptance pass.

### Day 7

- Prepare TestFlight signing path.
- Create entitlement request notes.
- Archive only if entitlement is ready.
- Otherwise continue with local-device demo build.

## Risks

### Family Controls Entitlement

Risk:

- TestFlight distribution depends on Apple approval.

Mitigation:

- Build/run locally with development signing immediately.
- Keep entitlement request parallel.
- Do not wait to implement.

### Location Reliability

Risk:

- Geofence events are not always instant.

Mitigation:

- Use region monitoring plus app foreground checks.
- Display last status update time.
- Allow manual refresh.

### User Circumvention

Risk:

- A student may revoke permissions or delete the app.

Mitigation:

- MVP logs and surfaces permission loss.
- Do not claim MDM-level enforcement.
- Later school deployment may require MDM or policy layer.

### Privacy Concerns

Risk:

- Route tracking for minors will raise objections.

Mitigation:

- Event-only location history.
- No route map in MVP.
- Export only compliance/attendance events.

## Definition of Done

The MVP is done when Jacob can:

1. Install the app on his iPhone.
2. Complete setup.
3. Select apps/categories to disable.
4. Create a circle around his current location.
5. Turn focus on.
6. See selected apps shielded while inside the circle.
7. Walk outside and see selected apps available again.
8. Manually unlock while inside and see the event logged.
9. Mark attendance Enter/Exit for at least two classes.
10. See attendance/focus/passing metrics.
11. Export local demo evidence.

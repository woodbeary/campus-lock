import Foundation
import Testing

@testable import CampusLockCore

@Suite("Campus Lock reducer")
struct CampusLockReducerTests {
    private let reducer = CampusLockReducer()
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("setup gates focus until permissions are complete")
    func setupGatesFocus() {
        var state = CampusLockState(isSetupComplete: false)

        reducer.reduce(&state, event: .startFocus(start))

        #expect(state.activeSession == nil)
        #expect(state.attendanceRecords.isEmpty)
        #expect(state.lockState == .setupRequired)
    }

    @Test("tap in starts focus and records attendance")
    func tapInStartsFocusAndAttendance() throws {
        var state = CampusLockState(isSetupComplete: true)

        reducer.reduce(&state, event: .startFocus(start))

        let activeSession = try #require(state.activeSession)
        #expect(activeSession.classSession.title == "Biology")
        #expect(state.attendanceRecords.count == 1)
        #expect(state.attendanceRecords[0].state == .present)
        #expect(state.isLocked)
    }

    @Test("leaving radius unlocks without ending attendance")
    func leavingRadiusUnlocksWithoutEndingAttendance() throws {
        var state = CampusLockState(isSetupComplete: true)
        state.zone = CampusZone(center: Coordinate(latitude: 33.0, longitude: -117.0), radiusMeters: 100)
        reducer.reduce(&state, event: .startFocus(start))

        reducer.reduce(
            &state,
            event: .leaveZone(Coordinate(latitude: 33.003, longitude: -117.0), start.addingTimeInterval(600))
        )

        #expect(state.activeSession != nil)
        #expect(state.activeZoneState == .outside)
        #expect(!state.isLocked)
        #expect((state.outsideDistanceMeters ?? 0) > 0)
        let record = try #require(state.attendanceRecords.last)
        #expect(record.state == .present)
        #expect(record.checkedOutAt == nil)
    }

    @Test("inside radius keeps focus locked")
    func insideRadiusKeepsFocusLocked() {
        var state = CampusLockState(isSetupComplete: true)
        state.zone = CampusZone(center: Coordinate(latitude: 33.0, longitude: -117.0), radiusMeters: 500)
        reducer.reduce(&state, event: .startFocus(start))

        reducer.reduce(
            &state,
            event: .leaveZone(Coordinate(latitude: 33.001, longitude: -117.0), start.addingTimeInterval(600))
        )

        #expect(state.activeSession != nil)
        #expect(state.activeZoneState == .inside)
        #expect(state.isLocked)
        #expect(state.attendanceRecords.last?.checkedOutAt == nil)
    }

    @Test("returning to zone relocks the active session")
    func returningToZoneRelocksActiveSession() {
        var state = CampusLockState(isSetupComplete: true)
        state.zone = CampusZone(center: Coordinate(latitude: 33.0, longitude: -117.0), radiusMeters: 100)
        reducer.reduce(&state, event: .startFocus(start))
        reducer.reduce(
            &state,
            event: .leaveZone(Coordinate(latitude: 33.003, longitude: -117.0), start.addingTimeInterval(600))
        )

        reducer.reduce(
            &state,
            event: .updateCurrentLocation(Coordinate(latitude: 33.0002, longitude: -117.0))
        )

        #expect(state.activeSession != nil)
        #expect(state.activeZoneState == .inside)
        #expect(state.isLocked)
        #expect(state.attendanceRecords.last?.checkedOutAt == nil)
    }

    @Test("manual unlock ends session with explicit state")
    func manualUnlock() throws {
        var state = CampusLockState(isSetupComplete: true)
        reducer.reduce(&state, event: .startFocus(start))

        reducer.reduce(&state, event: .manualUnlock(start.addingTimeInterval(180)))

        #expect(state.activeSession == nil)
        #expect(state.activeZoneState == .inside)
        let record = try #require(state.attendanceRecords.last)
        #expect(record.state == .manualUnlock)
        #expect(record.checkedOutAt == start.addingTimeInterval(180))
    }

    @Test("completed class cannot start twice in one day")
    func completedClassCannotStartTwiceInOneDay() {
        var state = CampusLockState(isSetupComplete: true)
        reducer.reduce(&state, event: .startFocus(start))
        reducer.reduce(&state, event: .manualUnlock(start.addingTimeInterval(180)))

        reducer.reduce(&state, event: .startFocus(start.addingTimeInterval(300)))

        #expect(state.activeSession == nil)
        #expect(state.attendanceRecords.count == 1)
    }

    @Test("in-progress attendance record does not count as done")
    func inProgressRecordDoesNotCountAsDone() {
        var state = CampusLockState(isSetupComplete: true)
        state.attendanceRecords = [
            AttendanceRecord(session: state.selectedClass, checkedInAt: start, state: .present)
        ]

        reducer.reduce(&state, event: .startFocus(start.addingTimeInterval(300)))

        #expect(state.activeSession != nil)
        #expect(state.attendanceRecords.count == 2)
    }

    @Test("current location update does not move saved zone")
    func currentLocationUpdateDoesNotMoveSavedZone() {
        var state = CampusLockState(isSetupComplete: true)
        let originalCenter = state.zone.center

        reducer.reduce(
            &state,
            event: .updateCurrentLocation(Coordinate(latitude: 34.0, longitude: -118.0))
        )

        #expect(state.currentLocation == Coordinate(latitude: 34.0, longitude: -118.0))
        #expect(state.zone.center == originalCenter)
    }

    @Test("reset clears attendance without removing setup")
    func resetClearsAttendanceWithoutRemovingSetup() {
        var state = CampusLockState(isSetupComplete: true)
        reducer.reduce(&state, event: .startFocus(start))
        reducer.reduce(&state, event: .startHallPass(start.addingTimeInterval(60), 300))

        reducer.reduce(&state, event: .resetAttendanceData)

        #expect(state.isSetupComplete)
        #expect(state.activeSession == nil)
        #expect(state.activeHallPass == nil)
        #expect(state.attendanceRecords.isEmpty)
    }

    @Test("hall pass pauses during an active class only")
    func hallPassRequiresActiveClass() throws {
        var state = CampusLockState(isSetupComplete: true)

        reducer.reduce(&state, event: .startHallPass(start, 300))
        #expect(state.activeHallPass == nil)

        reducer.reduce(&state, event: .startFocus(start))
        reducer.reduce(&state, event: .startHallPass(start.addingTimeInterval(60), 300))

        let hallPass = try #require(state.activeHallPass)
        #expect(hallPass.reason == "Restroom")
        #expect(hallPass.endsAt == start.addingTimeInterval(360))

        reducer.reduce(&state, event: .endHallPass(start.addingTimeInterval(120)))
        #expect(state.activeHallPass == nil)
        #expect(state.activeSession != nil)
    }

    @Test("hall pass cannot start outside the zone")
    func hallPassRequiresLockedZone() {
        var state = CampusLockState(isSetupComplete: true)
        state.zone = CampusZone(center: Coordinate(latitude: 33.0, longitude: -117.0), radiusMeters: 100)
        reducer.reduce(&state, event: .startFocus(start))
        reducer.reduce(
            &state,
            event: .leaveZone(Coordinate(latitude: 33.003, longitude: -117.0), start.addingTimeInterval(600))
        )

        reducer.reduce(&state, event: .startHallPass(start.addingTimeInterval(700), 300))

        #expect(state.activeSession != nil)
        #expect(state.activeHallPass == nil)
    }

    @Test("legacy state decodes with inside zone state")
    func legacyStateDecodesWithInsideZoneState() throws {
        let data = try JSONEncoder().encode(CampusLockState(isSetupComplete: true))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "activeZoneState")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(CampusLockState.self, from: legacyData)

        #expect(decoded.activeZoneState == .inside)
    }

    @Test("safety critical categories cannot be blocked", arguments: [AppCategory.phone, .messages, .maps])
    func safetyCriticalCategoriesStayAllowed(category: AppCategory) {
        var policy = AppPolicy()

        policy.setBlocked(category, isBlocked: true)

        #expect(!policy.isBlocked(category))
    }

    @Test("radius clamps to supported MVP range")
    func radiusClamps() {
        var state = CampusLockState(isSetupComplete: true)

        reducer.reduce(&state, event: .updateRadius(10))
        #expect(state.zone.radiusMeters == 50)

        reducer.reduce(&state, event: .updateRadius(900))
        #expect(state.zone.radiusMeters == 500)
    }
}

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

    @Test("leaving radius checks out and unlocks")
    func leavingRadiusUnlocks() throws {
        var state = CampusLockState(isSetupComplete: true)
        state.zone = CampusZone(center: Coordinate(latitude: 33.0, longitude: -117.0), radiusMeters: 100)
        reducer.reduce(&state, event: .startFocus(start))

        reducer.reduce(
            &state,
            event: .leaveZone(Coordinate(latitude: 33.003, longitude: -117.0), start.addingTimeInterval(600))
        )

        #expect(state.activeSession == nil)
        let record = try #require(state.attendanceRecords.last)
        #expect(record.state == .checkedOut)
        #expect(record.checkedOutAt == start.addingTimeInterval(600))
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
        #expect(state.attendanceRecords.last?.checkedOutAt == nil)
    }

    @Test("manual unlock ends session with explicit state")
    func manualUnlock() throws {
        var state = CampusLockState(isSetupComplete: true)
        reducer.reduce(&state, event: .startFocus(start))

        reducer.reduce(&state, event: .manualUnlock(start.addingTimeInterval(180)))

        #expect(state.activeSession == nil)
        let record = try #require(state.attendanceRecords.last)
        #expect(record.state == .manualUnlock)
        #expect(record.checkedOutAt == start.addingTimeInterval(180))
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

import CampusLockCore
import Foundation
import Testing

@Suite("Campus Lock iOS target smoke tests")
struct CampusLockSmokeTests {
    @Test("sample schedule contains the MVP class order")
    func sampleSchedule() throws {
        let schedule = ClassSession.sampleSchedule(referenceDate: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(schedule.map(\.title) == ["English", "History", "Biology", "Algebra", "Studio", "Practice"])
        #expect(schedule[2].room == "Room 204")
    }

    @Test("tap in to leave zone is the complete demo path")
    func completeDemoPath() throws {
        let reducer = CampusLockReducer()
        var state = CampusLockState(isSetupComplete: true)
        state.zone = CampusZone(center: Coordinate(latitude: 33.0, longitude: -117.0), radiusMeters: 80)
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        reducer.reduce(&state, event: .startFocus(start))
        reducer.reduce(&state, event: .leaveZone(Coordinate(latitude: 33.002, longitude: -117.0), start.addingTimeInterval(60)))

        #expect(!state.isLocked)
        #expect(state.attendanceRecords.last?.state == .checkedOut)
    }
}

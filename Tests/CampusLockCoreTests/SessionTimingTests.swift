import Foundation
import Testing

@testable import CampusLockCore

@Suite("Session timing")
struct SessionTimingTests {
    @Test("formats elapsed clock")
    func formatsSessionClocks() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let session = FocusSession(
            classSession: ClassSession(period: 1, title: "Biology", room: "204", startsAt: start, durationMinutes: 47),
            zone: CampusZone(center: Coordinate(latitude: 33, longitude: -117), radiusMeters: 100),
            startedAt: start
        )

        let timing = SessionTiming(session: session, now: start.addingTimeInterval(125))

        #expect(timing.elapsedClock == "2:05")
    }

    @Test("clamps negative timing to zero")
    func clampsNegativeTiming() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let session = FocusSession(
            classSession: ClassSession(period: 1, title: "Biology", room: "204", startsAt: start, durationMinutes: 1),
            zone: CampusZone(center: Coordinate(latitude: 33, longitude: -117), radiusMeters: 100),
            startedAt: start
        )

        #expect(SessionTiming(session: session, now: start.addingTimeInterval(-10)).elapsedClock == "0:00")
    }

    @Test("uses hour clock for long sessions")
    func hourClock() {
        #expect(SessionTiming.clock(3_665) == "1:01:05")
    }
}

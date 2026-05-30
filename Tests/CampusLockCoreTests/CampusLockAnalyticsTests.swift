import Foundation
import Testing

@testable import CampusLockCore

@Suite("Campus Lock analytics")
struct CampusLockAnalyticsTests {
    @Test("dashboard metrics summarize attendance, lock time, and passing periods")
    func dashboardMetrics() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let schedule = ClassSession.sampleSchedule(referenceDate: now)
        let records = [
            AttendanceRecord(
                session: schedule[0],
                checkedInAt: now,
                checkedOutAt: now.addingTimeInterval(47 * 60),
                state: .checkedOut
            ),
            AttendanceRecord(
                session: schedule[1],
                checkedInAt: now.addingTimeInterval(60 * 60),
                checkedOutAt: now.addingTimeInterval(107 * 60),
                state: .manualUnlock
            )
        ]

        let metrics = CampusLockAnalytics.dashboardMetrics(
            attendanceRecords: records,
            scheduledClassCount: 6,
            passingDurations: [180, 260, 210]
        )

        #expect(metrics.attendanceRate == 2.0 / 6.0)
        #expect(metrics.averagePassingSeconds == 650.0 / 3.0)
        #expect(metrics.lockedSeconds == 94 * 60)
        #expect(metrics.longPassingPeriods == 1)
    }

    @Test("attendance rate is capped at one hundred percent")
    func attendanceRateCapsAtOneHundredPercent() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let schedule = ClassSession.sampleSchedule(referenceDate: now)
        let records = schedule.map { session in
            AttendanceRecord(session: session, checkedInAt: now, state: .manualUnlock)
        } + [
            AttendanceRecord(session: schedule[0], checkedInAt: now.addingTimeInterval(60), state: .manualUnlock)
        ]

        let metrics = CampusLockAnalytics.dashboardMetrics(
            attendanceRecords: records,
            scheduledClassCount: schedule.count,
            passingDurations: []
        )

        #expect(metrics.attendanceRate == 1)
    }

    @Test("weekly buckets use real attendance records")
    func weeklyBucketsUseRealRecords() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 9)))
        let tuesday = try #require(calendar.date(byAdding: .day, value: 1, to: monday))
        let schedule = ClassSession.sampleSchedule(referenceDate: monday)
        let records = [
            AttendanceRecord(
                session: schedule[0],
                checkedInAt: monday,
                checkedOutAt: monday.addingTimeInterval(900),
                state: .checkedOut
            ),
            AttendanceRecord(
                session: schedule[1],
                checkedInAt: tuesday,
                checkedOutAt: tuesday.addingTimeInterval(600),
                state: .manualUnlock
            )
        ]

        let buckets = CampusLockAnalytics.weekBuckets(
            attendanceRecords: records,
            referenceDate: monday,
            calendar: calendar
        )

        #expect(buckets.count == 7)
        #expect(buckets[1].lockedSeconds == 900)
        #expect(buckets[2].lockedSeconds == 600)
        #expect(buckets[2].manualUnlockCount == 1)
        #expect(buckets.reduce(0) { $0 + $1.attendedCount } == 2)
    }

    @Test("day buckets use schedule periods without fake durations")
    func dayBucketsUseSchedulePeriods() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10)))
        let schedule = ClassSession.sampleSchedule(referenceDate: date)
        let records = [
            AttendanceRecord(
                session: schedule[2],
                checkedInAt: date,
                checkedOutAt: date.addingTimeInterval(47 * 60),
                state: .checkedOut
            )
        ]

        let buckets = CampusLockAnalytics.dayBuckets(
            attendanceRecords: records,
            schedule: schedule,
            referenceDate: date,
            calendar: calendar
        )

        #expect(buckets.map(\.label) == ["1", "2", "3", "4", "5", "6"])
        #expect(buckets[2].lockedSeconds == 47 * 60)
        #expect(buckets.filter { $0.lockedSeconds > 0 }.count == 1)
    }
}

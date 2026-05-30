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
}

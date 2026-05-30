import Foundation

public enum CampusLockAnalytics {
    public static func dashboardMetrics(
        attendanceRecords: [AttendanceRecord],
        scheduledClassCount: Int,
        passingDurations: [TimeInterval]
    ) -> DashboardMetrics {
        let presentCount = attendanceRecords.filter { $0.state == .present || $0.state == .checkedOut || $0.state == .manualUnlock }.count
        let attendanceRate = scheduledClassCount == 0 ? 0 : Double(presentCount) / Double(scheduledClassCount)
        let averagePassingSeconds = passingDurations.isEmpty ? 0 : passingDurations.reduce(0, +) / Double(passingDurations.count)
        let lockedSeconds = attendanceRecords.reduce(0) { total, record in
            guard let checkedOutAt = record.checkedOutAt else { return total }
            return total + checkedOutAt.timeIntervalSince(record.checkedInAt)
        }
        let longPassingPeriods = passingDurations.filter { $0 > 4 * 60 }.count
        return DashboardMetrics(
            attendanceRate: attendanceRate,
            averagePassingSeconds: averagePassingSeconds,
            lockedSeconds: lockedSeconds,
            longPassingPeriods: longPassingPeriods
        )
    }
}

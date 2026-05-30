import Foundation

public struct FocusStatBucket: Equatable, Identifiable, Sendable {
    public var id: String
    public var label: String
    public var lockedSeconds: TimeInterval
    public var attendedCount: Int
    public var manualUnlockCount: Int

    public init(
        id: String,
        label: String,
        lockedSeconds: TimeInterval = 0,
        attendedCount: Int = 0,
        manualUnlockCount: Int = 0
    ) {
        self.id = id
        self.label = label
        self.lockedSeconds = lockedSeconds
        self.attendedCount = attendedCount
        self.manualUnlockCount = manualUnlockCount
    }
}

public enum CampusLockAnalytics {
    public static func dashboardMetrics(
        attendanceRecords: [AttendanceRecord],
        scheduledClassCount: Int,
        passingDurations: [TimeInterval]
    ) -> DashboardMetrics {
        let presentCount = attendanceRecords.filter { $0.state == .present || $0.state == .checkedOut || $0.state == .manualUnlock }.count
        let attendanceRate = scheduledClassCount == 0 ? 0 : min(1, Double(presentCount) / Double(scheduledClassCount))
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

    public static func weekBuckets(
        attendanceRecords: [AttendanceRecord],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> [FocusStatBucket] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return [] }
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
            let weekdayIndex = max(0, min(symbols.count - 1, calendar.component(.weekday, from: date) - 1))
            let records = attendanceRecords.filter { calendar.isDate($0.checkedInAt, inSameDayAs: date) }
            return bucket(
                id: "week-\(offset)",
                label: symbols[weekdayIndex],
                records: records
            )
        }
    }

    public static func dayBuckets(
        attendanceRecords: [AttendanceRecord],
        schedule: [ClassSession],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> [FocusStatBucket] {
        schedule.map { classSession in
            let records = attendanceRecords.filter { record in
                calendar.isDate(record.checkedInAt, inSameDayAs: referenceDate)
                    && record.session.period == classSession.period
            }
            return bucket(
                id: "period-\(classSession.period)",
                label: "\(classSession.period)",
                records: records
            )
        }
    }

    private static func bucket(
        id: String,
        label: String,
        records: [AttendanceRecord]
    ) -> FocusStatBucket {
        FocusStatBucket(
            id: id,
            label: label,
            lockedSeconds: records.reduce(0) { total, record in
                guard let checkedOutAt = record.checkedOutAt else { return total }
                return total + max(0, checkedOutAt.timeIntervalSince(record.checkedInAt))
            },
            attendedCount: records.count,
            manualUnlockCount: records.filter { $0.state == .manualUnlock }.count
        )
    }
}

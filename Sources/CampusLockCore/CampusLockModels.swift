import Foundation

public struct Coordinate: Codable, Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CampusZone: Codable, Equatable, Sendable {
    public var center: Coordinate
    public var radiusMeters: Double
    public var label: String

    public init(center: Coordinate, radiusMeters: Double, label: String = "Class Zone") {
        self.center = center
        self.radiusMeters = radiusMeters
        self.label = label
    }

    public func contains(_ coordinate: Coordinate) -> Bool {
        distanceMeters(to: coordinate) <= radiusMeters
    }

    public func distanceMeters(to coordinate: Coordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = center.latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let deltaLat = (coordinate.latitude - center.latitude) * .pi / 180
        let deltaLon = (coordinate.longitude - center.longitude) * .pi / 180
        let haversine = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}

public enum AppCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case social
    case video
    case games
    case entertainment
    case shopping
    case messages
    case maps
    case phone

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .social: "Social"
        case .video: "Video"
        case .games: "Games"
        case .entertainment: "Entertainment"
        case .shopping: "Shopping"
        case .messages: "Messages"
        case .maps: "Maps"
        case .phone: "Phone"
        }
    }

    public var isSafetyCritical: Bool {
        self == .messages || self == .maps || self == .phone
    }
}

public struct AppPolicy: Codable, Equatable, Sendable {
    public var blockedCategories: Set<AppCategory>

    public init(blockedCategories: Set<AppCategory> = [.social, .video, .games]) {
        self.blockedCategories = blockedCategories.filter { !$0.isSafetyCritical }
    }

    public mutating func setBlocked(_ category: AppCategory, isBlocked: Bool) {
        guard !category.isSafetyCritical else { return }
        if isBlocked {
            blockedCategories.insert(category)
        } else {
            blockedCategories.remove(category)
        }
    }

    public func isBlocked(_ category: AppCategory) -> Bool {
        blockedCategories.contains(category)
    }
}

public struct ClassSession: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var period: Int
    public var title: String
    public var room: String
    public var startsAt: Date
    public var durationMinutes: Int

    public init(
        id: UUID = UUID(),
        period: Int,
        title: String,
        room: String,
        startsAt: Date,
        durationMinutes: Int = 47
    ) {
        self.id = id
        self.period = period
        self.title = title
        self.room = room
        self.startsAt = startsAt
        self.durationMinutes = durationMinutes
    }
}

public enum AttendanceState: String, Codable, Sendable {
    case present
    case checkedOut
    case manualUnlock
}

public struct AttendanceRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var session: ClassSession
    public var checkedInAt: Date
    public var checkedOutAt: Date?
    public var state: AttendanceState

    public init(
        id: UUID = UUID(),
        session: ClassSession,
        checkedInAt: Date,
        checkedOutAt: Date? = nil,
        state: AttendanceState = .present
    ) {
        self.id = id
        self.session = session
        self.checkedInAt = checkedInAt
        self.checkedOutAt = checkedOutAt
        self.state = state
    }
}

public struct HallPass: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var endsAt: Date
    public var reason: String

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        durationSeconds: TimeInterval = 300,
        reason: String = "Restroom"
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endsAt = startedAt.addingTimeInterval(durationSeconds)
        self.reason = reason
    }

    public func isActive(at date: Date) -> Bool {
        date < endsAt
    }

    public func remainingSeconds(at date: Date) -> TimeInterval {
        max(0, endsAt.timeIntervalSince(date))
    }
}

public enum FocusLockState: Equatable, Sendable {
    case setupRequired
    case ready
    case locked(FocusSession)
    case unlocked(lastRecord: AttendanceRecord?)
}

public struct FocusSession: Codable, Equatable, Sendable {
    public var classSession: ClassSession
    public var zone: CampusZone
    public var startedAt: Date

    public init(classSession: ClassSession, zone: CampusZone, startedAt: Date) {
        self.classSession = classSession
        self.zone = zone
        self.startedAt = startedAt
    }
}

public struct DashboardMetrics: Equatable, Sendable {
    public var attendanceRate: Double
    public var averagePassingSeconds: TimeInterval
    public var lockedSeconds: TimeInterval
    public var longPassingPeriods: Int

    public init(
        attendanceRate: Double,
        averagePassingSeconds: TimeInterval,
        lockedSeconds: TimeInterval,
        longPassingPeriods: Int
    ) {
        self.attendanceRate = attendanceRate
        self.averagePassingSeconds = averagePassingSeconds
        self.lockedSeconds = lockedSeconds
        self.longPassingPeriods = longPassingPeriods
    }
}

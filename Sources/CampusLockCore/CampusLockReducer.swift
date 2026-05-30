import Foundation

public struct CampusLockState: Codable, Equatable, Sendable {
    public var isSetupComplete: Bool
    public var policy: AppPolicy
    public var zone: CampusZone
    public var activeSession: FocusSession?
    public var attendanceRecords: [AttendanceRecord]
    public var selectedClass: ClassSession
    public var currentLocation: Coordinate?

    public init(
        isSetupComplete: Bool = false,
        policy: AppPolicy = AppPolicy(),
        zone: CampusZone = CampusZone(
            center: Coordinate(latitude: 33.6405, longitude: -117.8443),
            radiusMeters: 150,
            label: "Campus"
        ),
        activeSession: FocusSession? = nil,
        attendanceRecords: [AttendanceRecord] = [],
        selectedClass: ClassSession = ClassSession.sampleSchedule(referenceDate: Date())[2],
        currentLocation: Coordinate? = nil
    ) {
        self.isSetupComplete = isSetupComplete
        self.policy = policy
        self.zone = zone
        self.activeSession = activeSession
        self.attendanceRecords = attendanceRecords
        self.selectedClass = selectedClass
        self.currentLocation = currentLocation
    }

    public var lockState: FocusLockState {
        if !isSetupComplete { return .setupRequired }
        if let activeSession { return .locked(activeSession) }
        return .unlocked(lastRecord: attendanceRecords.last)
    }

    public var isLocked: Bool {
        activeSession != nil
    }
}

public enum CampusLockEvent: Equatable, Sendable {
    case completeSetup
    case updatePolicy(AppPolicy)
    case updateRadius(Double)
    case updateLocation(Coordinate)
    case startFocus(Date)
    case manualUnlock(Date)
    case leaveZone(Coordinate, Date)
    case selectClass(ClassSession)
}

public struct CampusLockReducer: Sendable {
    public init() {}

    public func reduce(_ state: inout CampusLockState, event: CampusLockEvent) {
        switch event {
        case .completeSetup:
            state.isSetupComplete = true

        case let .updatePolicy(policy):
            state.policy = policy

        case let .updateRadius(radius):
            state.zone.radiusMeters = min(max(radius, 50), 500)

        case let .updateLocation(coordinate):
            state.currentLocation = coordinate
            state.zone.center = coordinate

        case let .startFocus(date):
            guard state.isSetupComplete else { return }
            let session = FocusSession(classSession: state.selectedClass, zone: state.zone, startedAt: date)
            state.activeSession = session
            state.attendanceRecords.append(
                AttendanceRecord(session: state.selectedClass, checkedInAt: date, state: .present)
            )

        case let .manualUnlock(date):
            checkout(state: &state, at: date, state: .manualUnlock)

        case let .leaveZone(coordinate, date):
            state.currentLocation = coordinate
            guard let activeSession = state.activeSession else { return }
            if !activeSession.zone.contains(coordinate) {
                checkout(state: &state, at: date, state: .checkedOut)
            }

        case let .selectClass(classSession):
            guard state.activeSession == nil else { return }
            state.selectedClass = classSession
        }
    }

    private func checkout(state: inout CampusLockState, at date: Date, state attendanceState: AttendanceState) {
        guard state.activeSession != nil else { return }
        state.activeSession = nil
        guard var latestRecord = state.attendanceRecords.last else { return }
        latestRecord.checkedOutAt = date
        latestRecord.state = attendanceState
        state.attendanceRecords[state.attendanceRecords.count - 1] = latestRecord
    }
}

public extension ClassSession {
    static func sampleSchedule(referenceDate: Date) -> [ClassSession] {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: referenceDate)
        let rows: [(Int, String, String, Int, Int)] = [
            (1, "English", "Room 118", 8, 10),
            (2, "History", "Room 222", 9, 5),
            (3, "Biology", "Room 204", 10, 0),
            (4, "Algebra", "Room 310", 11, 5),
            (5, "Studio", "Room 12", 13, 10),
            (6, "Practice", "Gym", 14, 15)
        ]
        return rows.map { period, title, room, hour, minute in
            ClassSession(
                period: period,
                title: title,
                room: room,
                startsAt: calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) ?? startOfDay
            )
        }
    }
}

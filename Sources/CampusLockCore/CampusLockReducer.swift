import Foundation

public struct CampusLockState: Codable, Equatable, Sendable {
    public var isSetupComplete: Bool
    public var policy: AppPolicy
    public var zone: CampusZone
    public var activeSession: FocusSession?
    public var activeHallPass: HallPass?
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
        activeHallPass: HallPass? = nil,
        attendanceRecords: [AttendanceRecord] = [],
        selectedClass: ClassSession = ClassSession.sampleSchedule(referenceDate: Date())[2],
        currentLocation: Coordinate? = nil
    ) {
        self.isSetupComplete = isSetupComplete
        self.policy = policy
        self.zone = zone
        self.activeSession = activeSession
        self.activeHallPass = activeHallPass
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
    case startHallPass(Date, TimeInterval)
    case endHallPass(Date)
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
            guard state.activeSession == nil else { return }
            guard !hasRecordToday(for: state.selectedClass, at: date, in: state.attendanceRecords) else { return }
            let session = FocusSession(classSession: state.selectedClass, zone: state.zone, startedAt: date)
            state.activeSession = session
            state.activeHallPass = nil
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

        case let .startHallPass(date, duration):
            guard state.activeSession != nil else { return }
            state.activeHallPass = HallPass(startedAt: date, durationSeconds: duration)

        case .endHallPass:
            state.activeHallPass = nil
        }
    }

    private func checkout(state: inout CampusLockState, at date: Date, state attendanceState: AttendanceState) {
        guard state.activeSession != nil else { return }
        state.activeSession = nil
        state.activeHallPass = nil
        guard var latestRecord = state.attendanceRecords.last else { return }
        latestRecord.checkedOutAt = date
        latestRecord.state = attendanceState
        state.attendanceRecords[state.attendanceRecords.count - 1] = latestRecord
    }

    private func hasRecordToday(
        for classSession: ClassSession,
        at date: Date,
        in records: [AttendanceRecord],
        calendar: Calendar = .current
    ) -> Bool {
        records.contains { record in
            record.session.id == classSession.id
                && calendar.isDate(record.checkedInAt, inSameDayAs: date)
        }
    }
}

public extension ClassSession {
    static func sampleSchedule(referenceDate: Date) -> [ClassSession] {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: referenceDate)
        let rows: [(String, Int, String, String, Int, Int)] = [
            ("11111111-1111-4111-8111-111111111111", 1, "English", "Room 118", 8, 10),
            ("22222222-2222-4222-8222-222222222222", 2, "History", "Room 222", 9, 5),
            ("33333333-3333-4333-8333-333333333333", 3, "Biology", "Room 204", 10, 0),
            ("44444444-4444-4444-8444-444444444444", 4, "Algebra", "Room 310", 11, 5),
            ("55555555-5555-4555-8555-555555555555", 5, "Studio", "Room 12", 13, 10),
            ("66666666-6666-4666-8666-666666666666", 6, "Practice", "Gym", 14, 15)
        ]
        return rows.map { id, period, title, room, hour, minute in
            ClassSession(
                id: UUID(uuidString: id) ?? UUID(),
                period: period,
                title: title,
                room: room,
                startsAt: calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) ?? startOfDay
            )
        }
    }
}

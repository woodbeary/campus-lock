import Foundation

public enum ActiveZoneState: String, Codable, Equatable, Sendable {
    case inside
    case outside
}

public struct CampusLockState: Codable, Equatable, Sendable {
    public var isSetupComplete: Bool
    public var profile: CampusProfile
    public var policy: AppPolicy
    public var zone: CampusZone
    public var activeSession: FocusSession?
    public var activeZoneState: ActiveZoneState
    public var activeHallPass: HallPass?
    public var attendanceRecords: [AttendanceRecord]
    public var selectedClass: ClassSession
    public var currentLocation: Coordinate?

    public init(
        isSetupComplete: Bool = false,
        profile: CampusProfile = CampusProfile(),
        policy: AppPolicy = AppPolicy(),
        zone: CampusZone = CampusZone(
            center: Coordinate(latitude: 33.6405, longitude: -117.8443),
            radiusMeters: 150,
            label: "Campus"
        ),
        activeSession: FocusSession? = nil,
        activeZoneState: ActiveZoneState = .inside,
        activeHallPass: HallPass? = nil,
        attendanceRecords: [AttendanceRecord] = [],
        selectedClass: ClassSession = ClassSession.sampleSchedule(referenceDate: Date())[2],
        currentLocation: Coordinate? = nil
    ) {
        self.isSetupComplete = isSetupComplete
        self.profile = profile
        self.policy = policy
        self.zone = zone
        self.activeSession = activeSession
        self.activeZoneState = activeSession == nil ? .inside : activeZoneState
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
        activeSession != nil && activeZoneState == .inside
    }

    public var isOutsideActiveZone: Bool {
        activeSession != nil && activeZoneState == .outside
    }

    public var outsideDistanceMeters: Double? {
        guard let activeSession, let currentLocation, activeZoneState == .outside else { return nil }
        return max(0, activeSession.zone.distanceMeters(to: currentLocation) - activeSession.zone.radiusMeters)
    }

    private enum CodingKeys: String, CodingKey {
        case isSetupComplete
        case profile
        case policy
        case zone
        case activeSession
        case activeZoneState
        case activeHallPass
        case attendanceRecords
        case selectedClass
        case currentLocation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isSetupComplete = try container.decode(Bool.self, forKey: .isSetupComplete)
        profile = try container.decodeIfPresent(CampusProfile.self, forKey: .profile) ?? CampusProfile()
        policy = try container.decode(AppPolicy.self, forKey: .policy)
        zone = try container.decode(CampusZone.self, forKey: .zone)
        activeSession = try container.decodeIfPresent(FocusSession.self, forKey: .activeSession)
        if activeSession == nil {
            activeZoneState = .inside
        } else {
            activeZoneState = try container.decodeIfPresent(ActiveZoneState.self, forKey: .activeZoneState) ?? .inside
        }
        activeHallPass = try container.decodeIfPresent(HallPass.self, forKey: .activeHallPass)
        attendanceRecords = try container.decode([AttendanceRecord].self, forKey: .attendanceRecords)
        selectedClass = try container.decode(ClassSession.self, forKey: .selectedClass)
        currentLocation = try container.decodeIfPresent(Coordinate.self, forKey: .currentLocation)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isSetupComplete, forKey: .isSetupComplete)
        try container.encode(profile, forKey: .profile)
        try container.encode(policy, forKey: .policy)
        try container.encode(zone, forKey: .zone)
        try container.encodeIfPresent(activeSession, forKey: .activeSession)
        let encodedZoneState: ActiveZoneState = activeSession == nil ? .inside : activeZoneState
        try container.encode(encodedZoneState, forKey: .activeZoneState)
        try container.encodeIfPresent(activeHallPass, forKey: .activeHallPass)
        try container.encode(attendanceRecords, forKey: .attendanceRecords)
        try container.encode(selectedClass, forKey: .selectedClass)
        try container.encodeIfPresent(currentLocation, forKey: .currentLocation)
    }
}

public enum CampusLockEvent: Equatable, Sendable {
    case completeSetup
    case updateDisplayName(String)
    case selectSchool(CampusSchoolSelection)
    case updatePolicy(AppPolicy)
    case updateRadius(Double)
    case updateLocation(Coordinate)
    case updateCurrentLocation(Coordinate)
    case startFocus(Date)
    case manualUnlock(Date)
    case leaveZone(Coordinate, Date)
    case selectClass(ClassSession)
    case startHallPass(Date, TimeInterval)
    case endHallPass(Date)
    case resetAttendanceData
    case restartOnboarding
}

public struct CampusLockReducer: Sendable {
    public init() {}

    public func reduce(_ state: inout CampusLockState, event: CampusLockEvent) {
        switch event {
        case .completeSetup:
            state.isSetupComplete = true

        case let .updateDisplayName(displayName):
            state.profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        case let .selectSchool(school):
            state.profile.school = school

        case let .updatePolicy(policy):
            state.policy = policy

        case let .updateRadius(radius):
            state.zone.radiusMeters = min(max(radius, 50), 500)

        case let .updateLocation(coordinate):
            state.currentLocation = coordinate
            state.zone.center = coordinate

        case let .updateCurrentLocation(coordinate):
            state.currentLocation = coordinate
            if let activeSession = state.activeSession,
               state.activeZoneState == .outside,
               activeSession.zone.contains(coordinate) {
                state.activeZoneState = .inside
            }

        case let .startFocus(date):
            guard state.isSetupComplete else { return }
            guard state.activeSession == nil else { return }
            guard !hasCompletedRecordToday(for: state.selectedClass, at: date, in: state.attendanceRecords) else { return }
            let session = FocusSession(classSession: state.selectedClass, zone: state.zone, startedAt: date)
            state.activeSession = session
            state.activeZoneState = .inside
            state.activeHallPass = nil
            state.attendanceRecords.append(
                AttendanceRecord(session: state.selectedClass, checkedInAt: date, state: .present)
            )

        case let .manualUnlock(date):
            checkout(state: &state, at: date, state: .manualUnlock)

        case let .leaveZone(coordinate, _):
            state.currentLocation = coordinate
            guard let activeSession = state.activeSession else { return }
            if !activeSession.zone.contains(coordinate) {
                state.activeZoneState = .outside
                state.activeHallPass = nil
            }

        case let .selectClass(classSession):
            guard state.activeSession == nil else { return }
            state.selectedClass = classSession

        case let .startHallPass(date, duration):
            guard state.isLocked else { return }
            state.activeHallPass = HallPass(startedAt: date, durationSeconds: duration)

        case .endHallPass:
            state.activeHallPass = nil

        case .resetAttendanceData:
            state.activeSession = nil
            state.activeZoneState = .inside
            state.activeHallPass = nil
            state.attendanceRecords = []

        case .restartOnboarding:
            state.isSetupComplete = false
            state.profile = CampusProfile()
            state.activeSession = nil
            state.activeZoneState = .inside
            state.activeHallPass = nil
            state.attendanceRecords = []
        }
    }

    private func checkout(state: inout CampusLockState, at date: Date, state attendanceState: AttendanceState) {
        guard state.activeSession != nil else { return }
        state.activeSession = nil
        state.activeZoneState = .inside
        state.activeHallPass = nil
        guard var latestRecord = state.attendanceRecords.last else { return }
        latestRecord.checkedOutAt = date
        latestRecord.state = attendanceState
        state.attendanceRecords[state.attendanceRecords.count - 1] = latestRecord
    }

    private func hasCompletedRecordToday(
        for classSession: ClassSession,
        at date: Date,
        in records: [AttendanceRecord],
        calendar: Calendar = .current
    ) -> Bool {
        records.contains { record in
            record.session.id == classSession.id
                && calendar.isDate(record.checkedInAt, inSameDayAs: date)
                && record.checkedOutAt != nil
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

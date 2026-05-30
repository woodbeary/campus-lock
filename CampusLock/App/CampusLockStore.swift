import CampusLockCore
import Foundation
import Observation

#if canImport(FamilyControls)
import FamilyControls
#endif

@MainActor
@Observable
final class CampusLockStore {
    var state: CampusLockState
    var authorizationStatus: PermissionStatus = .notDetermined
    var locationStatus: PermissionStatus = .notDetermined
    var selectedTab: AppTab = .lock
    var isShowingAppPicker = false

    #if canImport(FamilyControls)
    var activitySelection = FamilyActivitySelection() {
        didSet {
            guard !isUITesting else { return }
            repository.saveActivitySelection(activitySelection)
        }
    }
    #endif

    @ObservationIgnored private let reducer = CampusLockReducer()
    @ObservationIgnored private let screenTimeController = ScreenTimeController()
    @ObservationIgnored private let locationController = LocationController()
    @ObservationIgnored private let repository = CampusLockRepository()
    @ObservationIgnored private let isUITesting: Bool

    init(
        state: CampusLockState = CampusLockState(),
        isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("--ui-testing")
    ) {
        self.isUITesting = isUITesting
        self.state = isUITesting ? state : repository.load() ?? state
        #if canImport(FamilyControls)
        if !isUITesting {
            activitySelection = repository.loadActivitySelection() ?? FamilyActivitySelection()
        }
        #endif
        locationController.onLocationUpdate = { [weak self] coordinate in
            self?.handleLocationUpdate(coordinate)
        }
        if isUITesting {
            apply(.completeSetup)
        }
    }

    var schedule: [ClassSession] {
        ClassSession.sampleSchedule(referenceDate: Date())
    }

    var metrics: DashboardMetrics {
        CampusLockAnalytics.dashboardMetrics(
            attendanceRecords: state.attendanceRecords,
            scheduledClassCount: schedule.count,
            passingDurations: [180, 260, 210, 298]
        )
    }

    var selectedShieldItemCount: Int {
        #if canImport(FamilyControls)
        activitySelection.applicationTokens.count
            + activitySelection.categoryTokens.count
            + activitySelection.webDomainTokens.count
        #else
        state.policy.blockedCategories.count
        #endif
    }

    var hasShieldSelection: Bool {
        isUITesting || selectedShieldItemCount > 0
    }

    var canStartFocus: Bool {
        state.isSetupComplete && hasShieldSelection
    }

    func completeSetup() async {
        if isUITesting {
            authorizationStatus = .approved
            locationStatus = .approved
            apply(.completeSetup)
            return
        }
        authorizationStatus = await screenTimeController.requestAuthorization()
        locationStatus = await locationController.requestAuthorization()
        if authorizationStatus.isUsable && locationStatus.isUsable {
            apply(.completeSetup)
            locationController.startUpdating()
        }
    }

    func setBlocked(_ category: AppCategory, isBlocked: Bool) {
        var policy = state.policy
        policy.setBlocked(category, isBlocked: isBlocked)
        apply(.updatePolicy(policy))
    }

    func updateRadius(_ radius: Double) {
        apply(.updateRadius(radius))
        locationController.monitor(zone: state.zone)
    }

    func selectClass(_ classSession: ClassSession) {
        apply(.selectClass(classSession))
    }

    func startFocus() {
        guard canStartFocus else {
            selectedTab = .apps
            return
        }
        apply(.startFocus(Date()))
        applyShield()
        locationController.monitor(zone: state.zone)
    }

    func manualUnlock() {
        apply(.manualUnlock(Date()))
        applyShield()
    }

    func exportAttendanceURL() throws -> URL {
        try AttendanceExporter.exportURL(records: state.attendanceRecords)
    }

    func handleLocationUpdate(_ coordinate: Coordinate) {
        if state.activeSession == nil {
            apply(.updateLocation(coordinate))
        } else {
            apply(.leaveZone(coordinate, Date()))
            applyShield()
        }
    }

    private func apply(_ event: CampusLockEvent) {
        reducer.reduce(&state, event: event)
        repository.save(state)
    }

    private func applyShield() {
        #if canImport(FamilyControls)
        screenTimeController.applyShield(isLocked: state.isLocked, selection: activitySelection)
        #else
        screenTimeController.applyShield(isLocked: state.isLocked)
        #endif
    }
}

enum PermissionStatus: Equatable {
    case notDetermined
    case approved
    case denied(String)

    var isUsable: Bool {
        if case .approved = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .notDetermined: "Not set"
        case .approved: "Ready"
        case let .denied(message): message.isEmpty ? "Denied" : message
        }
    }
}

enum AppTab: Hashable {
    case lock
    case apps
    case zone
    case stats
    case attendance
}

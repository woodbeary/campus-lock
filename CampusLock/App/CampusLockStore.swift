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
    var isRequestingPermissions = false
    var isLocating = false

    #if canImport(FamilyControls)
    var activitySelection = FamilyActivitySelection() {
        didSet {
            guard !isUITesting else { return }
            repository.saveActivitySelection(activitySelection)
            if hasShieldSelection {
                authorizationStatus = .approved
            }
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
        let arguments = ProcessInfo.processInfo.arguments
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
        locationController.onLocationFailure = { [weak self] in
            self?.isLocating = false
        }
        locationController.onAuthorizationChange = { [weak self] status in
            self?.handleLocationAuthorizationChange(status)
        }
        if isUITesting && !arguments.contains("--ui-testing-setup-required") {
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

    var customShieldItemCount: Int {
        #if canImport(FamilyControls)
        activitySelection.applicationTokens.count
            + activitySelection.categoryTokens.count
            + activitySelection.webDomainTokens.count
        #else
        state.policy.blockedCategories.count
        #endif
    }

    var selectedShieldItemCount: Int {
        customShieldItemCount
    }

    var hasShieldSelection: Bool {
        isUITesting || customShieldItemCount > 0
    }

    var screenTimeReady: Bool {
        authorizationStatus.isUsable || hasShieldSelection
    }

    var screenTimeStatusLabel: String {
        screenTimeReady ? "Ready" : authorizationStatus.label
    }

    var focusSetupSubtitle: String {
        hasShieldSelection ? "\(customShieldItemCount) custom selected" : "Recommended preset"
    }

    var focusMetricValue: String {
        hasShieldSelection ? "\(customShieldItemCount)" : "Preset"
    }

    var focusMetricLabel: String {
        hasShieldSelection ? "selected" : "focus"
    }

    var shouldShowSetup: Bool {
        !state.isSetupComplete || !screenTimeReady || !locationStatus.isUsable
    }

    var canStartFocus: Bool {
        state.isSetupComplete && screenTimeReady && locationStatus.isUsable
    }

    func refreshRuntimeStatus() async {
        guard !isUITesting else {
            authorizationStatus = .approved
            locationStatus = .approved
            return
        }
        authorizationStatus = screenTimeController.currentAuthorizationStatus()
        locationStatus = locationController.currentAuthorizationStatus()
        if locationStatus.isUsable {
            locationController.startUpdating()
            locationController.requestCurrentLocation()
        }
    }

    func completeSetup() async {
        if isUITesting {
            authorizationStatus = .approved
            locationStatus = .approved
            apply(.completeSetup)
            return
        }
        isRequestingPermissions = true
        defer { isRequestingPermissions = false }
        await requestScreenTimeAuthorization()
        await requestLocationRefresh()
        if screenTimeReady && locationStatus.isUsable {
            apply(.completeSetup)
            selectedTab = .zone
        }
    }

    @discardableResult
    func requestScreenTimeAuthorization() async -> Bool {
        if isUITesting {
            authorizationStatus = .approved
            return true
        }
        if hasShieldSelection {
            authorizationStatus = .approved
            return true
        }
        if authorizationStatus.isUsable {
            return true
        }
        authorizationStatus = await screenTimeController.requestAuthorization()
        return screenTimeReady
    }

    @discardableResult
    func requestLocationRefresh() async -> Bool {
        if isUITesting {
            locationStatus = .approved
            return true
        }
        isLocating = true
        if !locationStatus.isUsable {
            locationStatus = await locationController.requestAuthorization()
        }
        guard locationStatus.isUsable else {
            isLocating = false
            return false
        }
        locationController.startUpdating()
        locationController.requestCurrentLocation()
        return true
    }

    func openAppPicker() async {
        guard await requestScreenTimeAuthorization() else { return }
        isShowingAppPicker = true
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
        guard screenTimeReady && locationStatus.isUsable else {
            selectedTab = .lock
            return
        }
        guard canStartFocus else { return }
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
        isLocating = false
        if state.activeSession == nil {
            apply(.updateLocation(coordinate))
        } else {
            apply(.leaveZone(coordinate, Date()))
            applyShield()
        }
    }

    func handleLocationAuthorizationChange(_ status: PermissionStatus) {
        locationStatus = status
        guard status.isUsable else { return }
        locationController.startUpdating()
        locationController.requestCurrentLocation()
        if screenTimeReady && !state.isSetupComplete {
            apply(.completeSetup)
            selectedTab = .zone
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

enum AppTab: Hashable, CaseIterable {
    case lock
    case apps
    case zone
    case stats
    case attendance
}

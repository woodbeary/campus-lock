import CampusLockCore
import Foundation
import Observation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(FamilyControls)
import FamilyControls
#endif

@MainActor
@Observable
final class CampusLockStore {
    var state: CampusLockState
    var authorizationStatus: PermissionStatus = .notDetermined
    var locationStatus: PermissionStatus = .notDetermined
    var selectedTab: AppTab = .attendance
    var isShowingAppPicker = false
    var isRequestingPermissions = false
    var isLocating = false
    var isStartingFocus = false
    var hasConfirmedPermissionOnboarding = false
    var nfcScanState: NFCScanState = .idle

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
    @ObservationIgnored private let nfcSessionController = NFCSessionController()
    @ObservationIgnored private let repository = CampusLockRepository()
    @ObservationIgnored private let isUITesting: Bool
    @ObservationIgnored private let requiresSetupInUITests: Bool
    @ObservationIgnored private var pendingFocusStart = false
    @ObservationIgnored private var focusStartTask: Task<Void, Never>?

    init(
        state: CampusLockState = CampusLockState(),
        isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("--ui-testing")
    ) {
        let arguments = ProcessInfo.processInfo.arguments
        self.isUITesting = isUITesting
        requiresSetupInUITests = isUITesting && arguments.contains("--ui-testing-setup-required")
        self.state = Self.canonicalizeClassSelection(isUITesting ? state : repository.load() ?? state)
        #if canImport(FamilyControls)
        if !isUITesting {
            activitySelection = repository.loadActivitySelection() ?? FamilyActivitySelection()
        }
        #endif
        if !isUITesting {
            authorizationStatus = screenTimeController.currentAuthorizationStatus()
            locationStatus = locationController.currentAuthorizationStatus()
        }
        locationController.onLocationUpdate = { [weak self] coordinate in
            self?.handleLocationUpdate(coordinate)
        }
        locationController.onRegionExit = { [weak self] coordinate in
            self?.handleRegionExit(coordinate)
        }
        locationController.onLocationFailure = { [weak self] in
            self?.isLocating = false
            self?.isStartingFocus = false
            self?.pendingFocusStart = false
            self?.focusStartTask?.cancel()
        }
        locationController.onAuthorizationChange = { [weak self] status in
            self?.handleLocationAuthorizationChange(status)
        }
        nfcSessionController.onStateChange = { [weak self] state in
            self?.nfcScanState = state
        }
        nfcSessionController.onDetected = { [weak self] in
            self?.startFocus()
        }
        if isUITesting && !requiresSetupInUITests {
            apply(.updateDisplayName("Alex"))
            apply(.selectSchool(CampusSchoolSelection(name: "University High School", address: "Irvine, CA")))
            apply(.updateLocation(Coordinate(latitude: 33.6405, longitude: -117.8443)))
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
        authorizationStatus.isUsable
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

    var displayName: String {
        let name = state.profile.trimmedDisplayName
        return name.isEmpty ? "Alex" : name
    }

    var shouldShowSetup: Bool {
        !state.isSetupComplete || !state.profile.hasDisplayName || !state.profile.hasSchool
    }

    var shouldShowPermissionSetup: Bool {
        shouldShowSetup
    }

    var shouldShowZoneOnboarding: Bool {
        false
    }

    var canContinuePermissionOnboarding: Bool {
        screenTimeReady && locationStatus.isUsable
    }

    var canStartFocus: Bool {
        state.activeSession == nil && state.isSetupComplete && screenTimeReady && locationStatus.isUsable && state.currentLocation != nil
    }

    func refreshRuntimeStatus() async {
        guard !isUITesting else {
            if requiresSetupInUITests {
                return
            }
            authorizationStatus = .approved
            locationStatus = .approved
            if state.currentLocation == nil {
                apply(.updateLocation(Coordinate(latitude: 33.6405, longitude: -117.8443)))
            }
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
            hasConfirmedPermissionOnboarding = true
            if state.currentLocation == nil {
                apply(.updateLocation(Coordinate(latitude: 33.6405, longitude: -117.8443)))
            }
            return
        }
        isRequestingPermissions = true
        defer { isRequestingPermissions = false }
        await requestScreenTimeAuthorization()
        await requestLocationRefresh()
    }

    func confirmPermissionOnboarding() {
        guard canContinuePermissionOnboarding else { return }
        hasConfirmedPermissionOnboarding = true
    }

    func updateDisplayName(_ displayName: String) {
        apply(.updateDisplayName(displayName))
    }

    func selectSchool(_ school: CampusSchoolSelection) {
        apply(.selectSchool(school))
    }

    func openSystemSettings() {
        #if canImport(UIKit)
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
        #endif
    }

    @discardableResult
    func finishZoneSetup(selectHome: Bool = true) -> Bool {
        guard state.profile.hasDisplayName && state.profile.hasSchool else { return false }
        guard screenTimeReady && locationStatus.isUsable && state.currentLocation != nil else { return false }
        apply(.completeSetup)
        locationController.monitor(zone: state.zone)
        if selectHome {
            selectedTab = .attendance
        }
        return true
    }

    @discardableResult
    func requestScreenTimeAuthorization() async -> Bool {
        if isUITesting {
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
            if state.currentLocation == nil {
                apply(.updateLocation(Coordinate(latitude: 33.6405, longitude: -117.8443)))
            }
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
            selectedTab = .attendance
            return
        }
        guard state.isSetupComplete else { return }
        if isUITesting {
            if state.currentLocation == nil {
                apply(.updateLocation(Coordinate(latitude: 33.6405, longitude: -117.8443)))
            }
            beginFocus()
            return
        }

        isStartingFocus = true
        pendingFocusStart = true
        locationController.startUpdating()
        locationController.requestCurrentLocation()
        focusStartTask?.cancel()
        focusStartTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.pendingFocusStart else { return }
                if self.state.currentLocation != nil {
                    self.beginFocus()
                } else {
                    self.isStartingFocus = false
                    self.pendingFocusStart = false
                }
            }
        }
    }

    func startNFCEntryScan() {
        guard state.activeSession == nil else { return }
        if isUITesting {
            nfcScanState = .scanning
            return
        }
        nfcSessionController.beginScanning()
    }

    func cancelNFCEntryScan() {
        nfcSessionController.cancel()
    }

    func enterManuallyFromNFCSheet() {
        cancelNFCEntryScan()
        startFocus()
    }

    private func beginFocus() {
        guard canStartFocus else {
            isStartingFocus = false
            pendingFocusStart = false
            focusStartTask?.cancel()
            return
        }
        let wasLocked = state.isLocked
        apply(.startFocus(Date()))
        applyShield()
        locationController.monitor(zone: state.zone)
        isStartingFocus = false
        pendingFocusStart = false
        focusStartTask?.cancel()
        if !wasLocked && state.isLocked {
            CampusFeedback.locked()
        }
    }

    func manualUnlock() {
        let wasLocked = state.isLocked
        apply(.manualUnlock(Date()))
        applyShield()
        if wasLocked && !state.isLocked {
            CampusFeedback.unlocked()
        }
    }

    func startHallPass() {
        guard state.isLocked else { return }
        apply(.startHallPass(Date(), 300))
        applyShield()
    }

    func endHallPass() {
        guard state.activeHallPass != nil else { return }
        apply(.endHallPass(Date()))
        applyShield()
    }

    func resetAttendanceData() {
        focusStartTask?.cancel()
        pendingFocusStart = false
        isStartingFocus = false
        nfcSessionController.cancel()
        nfcScanState = .idle
        apply(.resetAttendanceData)
        applyShield()
    }

    func restartOnboarding() {
        focusStartTask?.cancel()
        pendingFocusStart = false
        isStartingFocus = false
        selectedTab = .attendance
        hasConfirmedPermissionOnboarding = false
        nfcSessionController.cancel()
        nfcScanState = .idle
        apply(.restartOnboarding)
        applyShield()
    }

    func expireHallPassIfNeeded(at date: Date) {
        guard let hallPass = state.activeHallPass, !hallPass.isActive(at: date) else { return }
        apply(.endHallPass(date))
        applyShield()
    }

    func exportAttendanceURL() throws -> URL {
        try AttendanceExporter.exportURL(records: state.attendanceRecords)
    }

    func handleLocationUpdate(_ coordinate: Coordinate) {
        isLocating = false
        if pendingFocusStart {
            pendingFocusStart = false
            focusStartTask?.cancel()
            apply(.updateLocation(coordinate))
            beginFocus()
        } else if state.activeSession == nil {
            apply(.updateLocation(coordinate))
        } else {
            handleActiveLocationUpdate(coordinate)
        }
    }

    func handleRegionExit(_ coordinate: Coordinate) {
        guard let activeSession = state.activeSession else {
            apply(.updateLocation(coordinate))
            return
        }
        let now = Date()
        let elapsedSeconds = now.timeIntervalSince(activeSession.startedAt)
        let exitDistance = activeSession.zone.distanceMeters(to: coordinate)
        let exitThreshold = max(activeSession.zone.radiusMeters + 35, activeSession.zone.radiusMeters * 1.2)
        guard elapsedSeconds >= 20, exitDistance >= exitThreshold else {
            apply(.updateCurrentLocation(coordinate))
            return
        }
        let wasLocked = state.isLocked
        let wasOutside = state.isOutsideActiveZone
        apply(.leaveZone(coordinate, now))
        handleZoneTransition(wasLocked: wasLocked, wasOutside: wasOutside)
    }

    func handleLocationAuthorizationChange(_ status: PermissionStatus) {
        locationStatus = status
        guard status.isUsable else { return }
        locationController.startUpdating()
        locationController.requestCurrentLocation()
    }

    private func apply(_ event: CampusLockEvent) {
        reducer.reduce(&state, event: event)
        repository.save(state)
    }

    private func handleActiveLocationUpdate(_ coordinate: Coordinate) {
        guard let activeSession = state.activeSession else {
            apply(.updateLocation(coordinate))
            return
        }
        let wasLocked = state.isLocked
        let wasOutside = state.isOutsideActiveZone
        let now = Date()
        let elapsedSeconds = now.timeIntervalSince(activeSession.startedAt)
        let exitDistance = activeSession.zone.distanceMeters(to: coordinate)
        let exitThreshold = max(activeSession.zone.radiusMeters + 35, activeSession.zone.radiusMeters * 1.2)
        if !state.isOutsideActiveZone, elapsedSeconds >= 20, exitDistance >= exitThreshold {
            apply(.leaveZone(coordinate, now))
        } else {
            apply(.updateCurrentLocation(coordinate))
        }
        handleZoneTransition(wasLocked: wasLocked, wasOutside: wasOutside)
    }

    private func applyShield() {
        let hallPassIsActive = state.activeHallPass?.isActive(at: Date()) == true
        let shouldShield = state.isLocked && !hallPassIsActive
        #if canImport(FamilyControls)
        screenTimeController.applyShield(isLocked: shouldShield, selection: activitySelection)
        #else
        screenTimeController.applyShield(isLocked: shouldShield)
        #endif
    }

    private func handleZoneTransition(wasLocked: Bool, wasOutside: Bool) {
        guard wasLocked != state.isLocked || wasOutside != state.isOutsideActiveZone else { return }
        applyShield()
        if !wasLocked && state.isLocked {
            CampusFeedback.locked()
        } else if wasLocked && !state.isLocked && state.isOutsideActiveZone {
            CampusFeedback.outsideZone()
        }
    }

    private static func canonicalizeClassSelection(_ state: CampusLockState) -> CampusLockState {
        var state = state
        if state.isSetupComplete && (!state.profile.hasDisplayName || !state.profile.hasSchool) {
            state.isSetupComplete = false
        }
        if state.isSetupComplete && state.currentLocation == nil {
            state.isSetupComplete = false
        }
        guard state.activeSession == nil else { return state }
        if let canonicalClass = ClassSession.sampleSchedule(referenceDate: Date()).first(where: { classSession in
            classSession.period == state.selectedClass.period
        }) {
            state.selectedClass = canonicalClass
        }
        return state
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

    static let primaryTabs: [AppTab] = [.attendance, .apps]
}

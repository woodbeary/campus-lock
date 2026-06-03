import CoreLocation
import CampusLockCore
import Foundation

@MainActor
final class LocationController: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((Coordinate) -> Void)?
    var onRegionExit: ((Coordinate) -> Void)?
    var onLocationFailure: (() -> Void)?
    var onAuthorizationChange: ((PermissionStatus) -> Void)?

    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<PermissionStatus, Never>?
    private var requestedAlwaysUpgrade = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
    }

    func currentAuthorizationStatus() -> PermissionStatus {
        permissionStatus(for: manager.authorizationStatus)
    }

    func requestAuthorization() async -> PermissionStatus {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            return .approved
        case .authorizedWhenInUse:
            requestedAlwaysUpgrade = true
            manager.requestAlwaysAuthorization()
            return .denied("Allow Always")
        case .denied, .restricted:
            return .denied("Location denied")
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        @unknown default:
            return .denied("Location unavailable")
        }
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func requestCurrentLocation() {
        guard manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse else { return }
        manager.requestLocation()
    }

    func monitor(zone: CampusZone) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: zone.center.latitude, longitude: zone.center.longitude),
            radius: zone.radiusMeters,
            identifier: "CampusLock.Zone"
        )
        region.notifyOnExit = true
        region.notifyOnEntry = false
        manager.startMonitoring(for: region)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in
            onLocationUpdate?(coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            onLocationFailure?()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let location = manager.location else { return }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in
            onRegionExit?(coordinate)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            finishAuthorization(status)
        }
    }

    private func finishAuthorization(_ status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }

        if status == .authorizedWhenInUse {
            requestedAlwaysUpgrade = true
            manager.requestAlwaysAuthorization()
        } else if status != .authorizedAlways {
            requestedAlwaysUpgrade = false
        }

        let permissionStatus = permissionStatus(for: status)
        if let authorizationContinuation {
            self.authorizationContinuation = nil
            authorizationContinuation.resume(returning: permissionStatus)
        }
        onAuthorizationChange?(permissionStatus)
    }

    private func permissionStatus(for status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways:
            return .approved
        case .authorizedWhenInUse:
            return .denied("Allow Always")
        case .denied, .restricted:
            return .denied("Location denied")
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied("Location unavailable")
        }
    }
}

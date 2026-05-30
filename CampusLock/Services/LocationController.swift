import CoreLocation
import CampusLockCore
import Foundation

@MainActor
final class LocationController: NSObject, CLLocationManagerDelegate {
    var onLocationUpdate: ((Coordinate) -> Void)?

    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<PermissionStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
    }

    func requestAuthorization() async -> PermissionStatus {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            return .approved
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            return .approved
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

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let location = manager.location else { return }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in
            onLocationUpdate?(coordinate)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            finishAuthorization(status)
        }
    }

    private func finishAuthorization(_ status: CLAuthorizationStatus) {
        guard let authorizationContinuation else { return }
        self.authorizationContinuation = nil
        switch status {
        case .authorizedAlways:
            authorizationContinuation.resume(returning: .approved)
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            authorizationContinuation.resume(returning: .approved)
        case .denied, .restricted:
            authorizationContinuation.resume(returning: .denied("Location denied"))
        case .notDetermined:
            self.authorizationContinuation = authorizationContinuation
        @unknown default:
            authorizationContinuation.resume(returning: .denied("Location unavailable"))
        }
    }
}

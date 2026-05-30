import Foundation

#if canImport(FamilyControls)
import FamilyControls
#endif

#if canImport(ManagedSettings)
import ManagedSettings
#endif

@MainActor
final class ScreenTimeController {
    #if canImport(ManagedSettings)
    private let store = ManagedSettingsStore(named: .init("CampusLockFocus"))
    #endif

    func currentAuthorizationStatus() -> PermissionStatus {
        #if canImport(FamilyControls)
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied("Screen Time denied")
        case .approved:
            return .approved
        @unknown default:
            return .denied("Screen Time unavailable")
        }
        #else
        return .approved
        #endif
    }

    func requestAuthorization() async -> PermissionStatus {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            return .approved
        } catch {
            return .denied(error.localizedDescription)
        }
        #else
        return .approved
        #endif
    }

    #if canImport(FamilyControls)
    func applyShield(isLocked: Bool, selection: FamilyActivitySelection) {
        #if canImport(ManagedSettings)
        guard isLocked else {
            store.clearAllSettings()
            return
        }

        let hasCustomSelection = !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty

        if hasCustomSelection {
            store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
            store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
            store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        } else {
            store.shield.applications = nil
            store.shield.applicationCategories = .all()
            store.shield.webDomains = nil
            store.shield.webDomainCategories = .all()
        }
        #endif
    }
    #else
    func applyShield(isLocked: Bool) {}
    #endif
}

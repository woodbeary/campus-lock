import SwiftUI

struct RootView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        Group {
            if store.shouldShowPermissionSetup {
                SetupView()
            } else if store.shouldShowZoneOnboarding {
                ZoneView(mode: .onboarding)
            } else {
                ZStack {
                    CampusTheme.background.ignoresSafeArea()
                    AttendanceView()
                        .transition(.opacity.combined(with: .offset(y: 6)))
                }
            }
        }
        .tint(CampusTheme.accent)
        .task {
            await store.refreshRuntimeStatus()
        }
    }
}

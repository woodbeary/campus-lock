import SwiftUI

struct RootView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        Group {
            if store.state.isSetupComplete {
                MainTabView()
            } else {
                SetupView()
            }
        }
        .tint(CampusTheme.accent)
    }
}

private struct MainTabView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            Tab("Lock", systemImage: "lock", value: .lock) {
                LockView()
            }
            Tab("Apps", systemImage: "square.grid.3x3", value: .apps) {
                AppsView()
            }
            Tab("Zone", systemImage: "location", value: .zone) {
                ZoneView()
            }
            Tab("Stats", systemImage: "clock", value: .stats) {
                InsightsView()
            }
            Tab("Attend", systemImage: "lanyardcard", value: .attendance) {
                AttendanceView()
            }
        }
    }
}

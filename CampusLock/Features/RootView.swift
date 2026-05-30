import SwiftUI

struct RootView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        MainTabView()
        .tint(CampusTheme.accent)
    }
}

private struct MainTabView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            lockTab
                .tabItem { Label(AppTab.lock.title, systemImage: AppTab.lock.symbol) }
                .tag(AppTab.lock)

            AppsView()
                .tabItem { Label(AppTab.apps.title, systemImage: AppTab.apps.symbol) }
                .tag(AppTab.apps)

            ZoneView()
                .tabItem { Label(AppTab.zone.title, systemImage: AppTab.zone.symbol) }
                .tag(AppTab.zone)

            InsightsView()
                .tabItem { Label(AppTab.stats.title, systemImage: AppTab.stats.symbol) }
                .tag(AppTab.stats)

            AttendanceView()
                .tabItem { Label(AppTab.attendance.title, systemImage: AppTab.attendance.symbol) }
                .tag(AppTab.attendance)
        }
        .tabViewStyle(.automatic)
        .background(CampusTheme.background.ignoresSafeArea())
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.bar, for: .tabBar)
        .animation(.snappy(duration: 0.18), value: store.selectedTab)
        .sensoryFeedback(.selection, trigger: store.selectedTab)
    }

    @ViewBuilder
    private var lockTab: some View {
        if store.state.isSetupComplete {
            LockView()
        } else {
            SetupView()
        }
    }
}

private extension AppTab {
    var title: String {
        switch self {
        case .lock: "Lock"
        case .apps: "Apps"
        case .zone: "Zone"
        case .stats: "Stats"
        case .attendance: "Attend"
        }
    }

    var symbol: String {
        switch self {
        case .lock: "lock.fill"
        case .apps: "square.grid.3x3.fill"
        case .zone: "location.fill"
        case .stats: "clock.fill"
        case .attendance: "lanyardcard.fill"
        }
    }
}

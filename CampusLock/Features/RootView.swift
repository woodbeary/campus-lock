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
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                currentTab
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.snappy(duration: 0.22), value: store.selectedTab)
                    .background(CampusTheme.background.ignoresSafeArea())
                    .zIndex(0)

                CampusFooterNav(selectedTab: $store.selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
                    .zIndex(10)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    @ViewBuilder
    private var currentTab: some View {
        switch store.selectedTab {
        case .lock:
            LockView()
        case .apps:
            AppsView()
        case .zone:
            ZoneView()
        case .stats:
            InsightsView()
        case .attendance:
            AttendanceView()
        }
    }
}

private struct CampusFooterNav: View {
    @Binding var selectedTab: AppTab
    private let tabs: [AppTab] = [.lock, .apps, .zone, .stats, .attendance]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(height: 19)

                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(selectedTab == tab ? CampusTheme.accent : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedTab == tab ? CampusTheme.accent.opacity(0.13) : Color.clear, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab.title.lowercased())")
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .frame(maxWidth: 390)
        .frame(height: CampusTheme.footerHeight)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
        .sensoryFeedback(.selection, trigger: selectedTab)
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

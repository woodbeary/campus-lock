import SwiftUI

struct RootView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Group {
            if store.shouldShowSetup {
                SetupView()
            } else {
                ZStack {
                    CampusTheme.background.ignoresSafeArea()
                    selectedScreen
                        .id(store.selectedTab)
                        .transition(.opacity.combined(with: .offset(y: 6)))
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CampusFooterMenu(selection: $store.selectedTab)
                }
            }
        }
        .tint(CampusTheme.accent)
        .animation(.snappy(duration: 0.18), value: store.selectedTab)
        .sensoryFeedback(.selection, trigger: store.selectedTab)
        .task {
            await store.refreshRuntimeStatus()
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch store.selectedTab {
        case .lock:
            lockTab
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

    @ViewBuilder
    private var lockTab: some View {
        LockView()
    }
}

private struct CampusFooterMenu: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                footerButton(for: tab)
            }
        }
        .padding(5)
        .frame(maxWidth: CampusTheme.contentMaxWidth)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator).opacity(0.16))
                .frame(height: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("footer.menu")
    }

    private func footerButton(for tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isSelected ? CampusTheme.accent.opacity(0.13) : Color.clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityIdentifier("tab.\(tab.accessibilityID)")
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

    var accessibilityID: String {
        switch self {
        case .lock: "lock"
        case .apps: "apps"
        case .zone: "zone"
        case .stats: "stats"
        case .attendance: "attendance"
        }
    }
}

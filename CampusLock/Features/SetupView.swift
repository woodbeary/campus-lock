import CampusLockCore
import SwiftUI

struct SetupView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var isWorking = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    permissionRows
                    mvpRule
                }
                .frame(maxWidth: .infinity, minHeight: max(0, proxy.size.height - 112), alignment: .topLeading)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 120)
                .campusLoadIn()
            }
            .defaultScrollAnchor(.top)
            .contentMargins(.top, 0, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomAction
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CampusTheme.background.ignoresSafeArea())
        .animation(.snappy(duration: 0.18), value: isWorking)
        .sensoryFeedback(.selection, trigger: isWorking)
    }

    private var header: some View {
        CampusScreenHeader(
            title: "Campus Lock",
            subtitle: "Set up once. Tap in at class. Walk out to unlock.",
            symbol: "lock.shield"
        )
    }

    private var permissionRows: some View {
        VStack(spacing: 10) {
            SetupRow(title: "Screen Time", subtitle: store.authorizationStatus.label, symbol: "lock", isReady: store.authorizationStatus.isUsable)
            SetupRow(title: "Apps", subtitle: appsSubtitle, symbol: "square.grid.3x3", isReady: store.hasShieldSelection)
            SetupRow(title: "Location", subtitle: store.locationStatus.label, symbol: "location", isReady: store.locationStatus.isUsable)
            SetupRow(title: "Attendance", subtitle: "Local check-ins", symbol: "lanyardcard", isReady: true)
        }
    }

    private var mvpRule: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MVP flow")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Tap in. Lock apps. Walk out.")
                .font(.headline.weight(.semibold))
            Text("No admin/student split for the demo.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard(padding: 14)
    }

    private var appsSubtitle: String {
        store.hasShieldSelection ? "\(store.selectedShieldItemCount) selected" : "Choose before first lock"
    }

    private var bottomAction: some View {
        CampusBottomBar {
            Button {
                Task {
                    isWorking = true
                    await store.completeSetup()
                    isWorking = false
                }
            } label: {
                HStack(spacing: 10) {
                    if isWorking {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color(.systemBackground))
                    }
                    Text(isWorking ? "Setting Up" : "Continue")
                }
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .disabled(isWorking)
            .accessibilityIdentifier("setup.continue")
        }
    }
}

private struct SetupRow: View {
    var title: String
    var subtitle: String
    var symbol: String
    var isReady: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 44, height: 44)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isReady ? "checkmark" : "circle")
                .font(.headline)
                .foregroundStyle(isReady ? CampusTheme.success : .secondary)
        }
        .campusCard(padding: 14)
    }
}

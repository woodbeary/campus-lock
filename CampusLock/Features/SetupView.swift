import CampusLockCore
import SwiftUI

struct SetupView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var isWorking = false

    var body: some View {
        CampusScreen {
            header
            permissionRows
            mvpRule
        }
        .campusFixedAction {
            bottomAction
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
        VStack(spacing: 0) {
            SetupRow(title: "Screen Time", subtitle: store.authorizationStatus.label, symbol: "lock", isReady: store.authorizationStatus.isUsable)
            CampusDivider()
            SetupRow(title: "Apps", subtitle: appsSubtitle, symbol: "square.grid.3x3", isReady: store.hasShieldSelection)
            CampusDivider()
            SetupRow(title: "Location", subtitle: store.locationStatus.label, symbol: "location", isReady: store.locationStatus.isUsable)
            CampusDivider()
            SetupRow(title: "Attendance", subtitle: "Local check-ins", symbol: "lanyardcard", isReady: true)
        }
        .campusCard(padding: 0)
    }

    private var mvpRule: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.walk.circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 42, height: 42)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Tap in. Lock apps. Walk out.")
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                Text("One founder demo surface.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard(padding: 14)
    }

    private var appsSubtitle: String {
        store.hasShieldSelection ? "\(store.selectedShieldItemCount) selected" : "Choose before first lock"
    }

    private var bottomAction: some View {
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
                Label(isWorking ? "Setting Up" : "Continue", systemImage: isWorking ? "hourglass" : "arrow.right")
                    .labelStyle(.titleAndIcon)
            }
        }
        .buttonStyle(CampusPrimaryButtonStyle())
        .disabled(isWorking)
        .accessibilityIdentifier("setup.continue")
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
                .font(.headline.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 38, height: 38)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct CampusDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 66)
    }
}

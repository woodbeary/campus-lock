import CampusLockCore
import SwiftUI

struct SetupView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        CampusScreen {
            header
            permissionRows
        }
        .campusFixedAction {
            bottomAction
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(CampusTheme.background.ignoresSafeArea())
        .animation(.snappy(duration: 0.18), value: store.isRequestingPermissions)
        .sensoryFeedback(.selection, trigger: store.isRequestingPermissions)
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
            SetupRow(title: "Screen Time", subtitle: store.screenTimeStatusLabel, symbol: "lock", isReady: store.screenTimeReady)
            CampusDivider()
            SetupRow(title: "Focus Preset", subtitle: appsSubtitle, symbol: "sparkles.rectangle.stack", isReady: store.screenTimeReady)
            CampusDivider()
            SetupRow(title: "Location", subtitle: store.locationStatus.label, symbol: "location", isReady: store.locationStatus.isUsable)
        }
        .campusCard(padding: 0)
    }

    private var appsSubtitle: String {
        store.focusSetupSubtitle
    }

    private var bottomAction: some View {
        Button {
            Task {
                await store.completeSetup()
            }
        } label: {
            HStack(spacing: 10) {
                if store.isRequestingPermissions {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(.systemBackground))
                }
                Label(store.isRequestingPermissions ? "Requesting" : "Allow & Continue", systemImage: store.isRequestingPermissions ? "hourglass" : "arrow.right")
                    .labelStyle(.titleAndIcon)
            }
        }
        .buttonStyle(CampusPrimaryButtonStyle())
        .disabled(store.isRequestingPermissions)
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 34, height: 34)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
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
        .padding(.vertical, 9)
    }
}

private struct CampusDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 62)
    }
}

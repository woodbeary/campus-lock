import CampusLockCore
import SwiftUI

struct SetupView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                header
                permissionRows
                mvpRule
                Spacer()
                Button {
                    Task {
                        isWorking = true
                        await store.completeSetup()
                        isWorking = false
                    }
                } label: {
                    Text(isWorking ? "Setting Up" : "Continue")
                }
                .buttonStyle(CampusPrimaryButtonStyle())
                .accessibilityIdentifier("setup.continue")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(CampusTheme.background)
            .navigationTitle("Campus")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set up once")
                .font(.title2.weight(.semibold))
            Text("Everything needed before the first lock.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var permissionRows: some View {
        VStack(spacing: 12) {
            SetupRow(title: "Screen Time", subtitle: store.authorizationStatus.label, symbol: "lock")
            SetupRow(title: "Apps", subtitle: "Choose what pauses", symbol: "square.grid.3x3")
            SetupRow(title: "Location", subtitle: store.locationStatus.label, symbol: "location")
            SetupRow(title: "Attendance", subtitle: "Local check-ins", symbol: "lanyardcard")
        }
    }

    private var mvpRule: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MVP flow")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Tap in. Lock apps. Walk out.")
                .font(.title3.weight(.semibold))
            Text("No admin/student split for the demo.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }
}

private struct SetupRow: View {
    var title: String
    var subtitle: String
    var symbol: String

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
            Image(systemName: "checkmark")
                .font(.headline)
                .foregroundStyle(CampusTheme.success)
        }
        .campusCard(padding: 14)
    }
}

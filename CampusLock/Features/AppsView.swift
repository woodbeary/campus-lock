import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppsView: View {
    @Environment(CampusLockStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var sheet: SettingsSheet?
    @State private var resetConfirmationIsPresented = false

    var body: some View {
        @Bindable var store = store
        CampusScreen {
            VStack(spacing: 10) {
                SettingsRow(
                    title: "Apps",
                    value: store.hasShieldSelection ? "\(store.selectedShieldItemCount) selected" : "Default",
                    symbol: "slider.horizontal.3"
                ) {
                    Task {
                        await store.openAppPicker()
                    }
                }
                .accessibilityIdentifier("apps.chooseSpecific")

                SettingsRow(
                    title: "Zone",
                    value: "\(Int(store.state.zone.radiusMeters)) m",
                    symbol: "location.circle"
                ) {
                    sheet = .zone
                }
                .accessibilityIdentifier("settings.zone")

                SettingsRow(
                    title: "Stats",
                    value: "\(Int(store.metrics.attendanceRate * 100))%",
                    symbol: "chart.bar.xaxis"
                ) {
                    sheet = .stats
                }
                .accessibilityIdentifier("settings.stats")

                SettingsRow(
                    title: "Reset",
                    value: "Clear data",
                    symbol: "arrow.counterclockwise"
                ) {
                    resetConfirmationIsPresented = true
                }
                .accessibilityIdentifier("settings.reset")
            }
        }
        .sensoryFeedback(.selection, trigger: sheet)
        .confirmationDialog("Reset", isPresented: $resetConfirmationIsPresented, titleVisibility: .visible) {
            Button("Clear Data", role: .destructive) {
                store.resetAttendanceData()
            }
            Button("Restart Onboarding", role: .destructive) {
                store.restartOnboarding()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $store.isShowingAppPicker, selection: $store.activitySelection)
        #endif
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .zone:
                ZoneView(mode: .settings)
                    .presentationDetents([.large])
            case .stats:
                InsightsView()
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

private enum SettingsSheet: String, Identifiable {
    case zone
    case stats

    var id: String { rawValue }
}

private struct SettingsRow: View {
    var title: String
    var value: String
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CampusTheme.accent)
                    .frame(width: 42, height: 42)
                    .background(CampusTheme.accent.opacity(0.12), in: Circle())

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .campusCard(padding: 0)
    }
}

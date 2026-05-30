import SwiftUI

struct InsightsView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var isPreparingExport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CampusScreenHeader(
                    title: "Stats",
                    subtitle: "Founder-ready attendance and focus signals.",
                    symbol: "clock"
                )
                HStack(spacing: 12) {
                    MetricTile(value: "\(Int(store.metrics.attendanceRate * 100))%", label: "present")
                    MetricTile(value: "\(Int(store.metrics.averagePassingSeconds / 60))m", label: "avg pass")
                    MetricTile(value: String(format: "%.1fh", store.metrics.lockedSeconds / 3600), label: "locked")
                }
                WeeklyChart()
                    .campusCard()
                InsightCard(title: "Signal", value: "Long passing periods", detail: "Average is up 38 sec this week.")
                InsightCard(title: "Export", value: "Attendance · focus · zones", detail: "CSV stays local until shared.")
            }
            .padding(20)
            .padding(.bottom, 96)
            .campusLoadIn()
        }
        .background(CampusTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CampusBottomBar {
                if let exportURL, !isPreparingExport {
                    ShareLink(item: exportURL) {
                        Text("Share CSV")
                    }
                    .buttonStyle(CampusPrimaryButtonStyle())
                } else {
                    Button {
                        Task { @MainActor in
                            isPreparingExport = true
                            defer { isPreparingExport = false }
                            do {
                                exportURL = try store.exportAttendanceURL()
                            } catch {
                                exportError = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isPreparingExport {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color(.systemBackground))
                            }
                            Text(isPreparingExport ? "Preparing" : "Prepare CSV")
                        }
                    }
                    .buttonStyle(CampusPrimaryButtonStyle())
                    .disabled(isPreparingExport)
                    .accessibilityIdentifier("insights.prepareCSV")
                }
            }
        }
        .sensoryFeedback(.selection, trigger: isPreparingExport)
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "Could not create the CSV.")
        }
    }
}

private struct MetricTile: View {
    var value: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }
}

private struct WeeklyChart: View {
    private let values: [Double] = [0.56, 0.78, 0.68, 0.91, 0.73, 0.34, 0.42]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Week")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(index < 5 ? CampusTheme.accent : Color(.systemGray5))
                        .frame(height: 160 * value)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Weekly focus chart")
        }
    }
}

private struct InsightCard: View {
    var title: String
    var value: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }
}

import SwiftUI

struct InsightsView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        CampusScreen {
            HStack(spacing: 10) {
                MetricTile(value: "\(Int(store.metrics.attendanceRate * 100))%", label: "present")
                MetricTile(value: "\(Int(store.metrics.averagePassingSeconds / 60))m", label: "avg pass")
                MetricTile(value: String(format: "%.1fh", store.metrics.lockedSeconds / 3600), label: "locked")
            }
            WeeklyChart()
                .campusCard()
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
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard(padding: 14)
    }
}

private struct WeeklyChart: View {
    private let values: [Double] = [0.56, 0.78, 0.68, 0.91, 0.73, 0.34, 0.42]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Week")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(index < 5 ? CampusTheme.accent : Color(.systemGray5))
                        .frame(height: 132 * value)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 148)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Weekly focus chart")
        }
    }
}

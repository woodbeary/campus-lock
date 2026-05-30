import CampusLockCore
import SwiftUI

struct InsightsView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var range: InsightRange = .week
    @State private var selectedBucketID: String?

    private var buckets: [FocusStatBucket] {
        switch range {
        case .day:
            CampusLockAnalytics.dayBuckets(
                attendanceRecords: store.state.attendanceRecords,
                schedule: store.schedule,
                referenceDate: Date()
            )
        case .week:
            CampusLockAnalytics.weekBuckets(
                attendanceRecords: store.state.attendanceRecords,
                referenceDate: Date()
            )
        }
    }

    private var selectedBucket: FocusStatBucket? {
        buckets.first { $0.id == selectedBucketID }
            ?? buckets.last { $0.attendedCount > 0 }
            ?? buckets.last
    }

    private var totalLockedSeconds: TimeInterval {
        buckets.reduce(0) { $0 + $1.lockedSeconds }
    }

    private var totalSessions: Int {
        buckets.reduce(0) { $0 + $1.attendedCount }
    }

    var body: some View {
        CampusScreen {
            Picker("", selection: $range) {
                ForEach(InsightRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: range) { _, _ in selectedBucketID = nil }
            .accessibilityIdentifier("insights.range")

            HStack(spacing: 10) {
                MetricTile(value: "\(totalSessions)", label: "sessions")
                MetricTile(value: duration(totalLockedSeconds), label: "locked")
                MetricTile(value: duration(averageLockedSeconds), label: "avg")
            }

            InsightChart(
                buckets: buckets,
                selectedBucketID: selectedBucket?.id,
                onSelect: { selectedBucketID = $0.id }
            )
            .campusCard()

            InsightDetail(bucket: selectedBucket, range: range)
        }
        .sensoryFeedback(.selection, trigger: selectedBucketID)
    }

    private var averageLockedSeconds: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalLockedSeconds / Double(totalSessions)
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 { return "\(minutes)m" }
        let hours = Double(minutes) / 60
        return String(format: "%.1fh", hours)
    }
}

private enum InsightRange: String, CaseIterable, Identifiable {
    case day
    case week

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
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

private struct InsightChart: View {
    var buckets: [FocusStatBucket]
    var selectedBucketID: String?
    var onSelect: (FocusStatBucket) -> Void

    private var maxLockedSeconds: TimeInterval {
        max(buckets.map(\.lockedSeconds).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(buckets) { bucket in
                    Button {
                        onSelect(bucket)
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(fill(for: bucket))
                                .frame(height: barHeight(for: bucket))
                                .frame(maxWidth: .infinity, maxHeight: 136, alignment: .bottom)
                            Text(bucket.label)
                                .font(.caption2.weight(bucket.id == selectedBucketID ? .bold : .medium))
                                .foregroundStyle(bucket.id == selectedBucketID ? CampusTheme.accent : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(bucket.id == selectedBucketID ? "insights.bucket.selected" : "insights.bucket")
                }
            }
            .frame(height: 164, alignment: .bottom)

            if buckets.allSatisfy({ $0.attendedCount == 0 }) {
                Text("No sessions yet")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .accessibilityIdentifier("insights.empty")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func barHeight(for bucket: FocusStatBucket) -> CGFloat {
        if bucket.lockedSeconds <= 0 {
            return bucket.attendedCount > 0 ? 12 : 5
        }
        return max(18, CGFloat(bucket.lockedSeconds / maxLockedSeconds) * 132)
    }

    private func fill(for bucket: FocusStatBucket) -> Color {
        if bucket.id == selectedBucketID {
            return CampusTheme.accent
        }
        if bucket.attendedCount > 0 {
            return CampusTheme.accent.opacity(0.42)
        }
        return Color(.systemGray5)
    }
}

private struct InsightDetail: View {
    var bucket: FocusStatBucket?
    var range: InsightRange

    var body: some View {
        HStack(spacing: 10) {
            MetricTile(value: bucket?.label ?? "—", label: range == .day ? "period" : "day")
            MetricTile(value: "\(bucket?.attendedCount ?? 0)", label: "sessions")
            MetricTile(value: duration(bucket?.lockedSeconds ?? 0), label: "locked")
        }
        .accessibilityIdentifier("insights.detail")
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 { return "\(minutes)m" }
        return String(format: "%.1fh", Double(minutes) / 60)
    }
}

import CampusLockCore
import SwiftUI

struct LockView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        Group {
            if store.state.isLocked {
                FocusActiveView()
            } else if case let .unlocked(lastRecord) = store.state.lockState, lastRecord != nil {
                UnlockedView(record: lastRecord)
            } else {
                ReadyView()
            }
        }
        .background(CampusTheme.background)
    }
}

private struct ReadyView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        CampusScreen {
            header
            readyCard
            metricsRow
        }
        .campusFixedAction {
            Button {
                store.startFocus()
            } label: {
                Label("Tap In", systemImage: "lock.fill")
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .accessibilityIdentifier("lock.startFocus")
        }
    }

    private var averagePassingMinutes: Int {
        max(1, Int((store.metrics.averagePassingSeconds / 60).rounded()))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 40, height: 40)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(store.state.selectedClass.title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("Period \(store.state.selectedClass.period) · \(store.state.selectedClass.room)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(Int(store.state.zone.radiusMeters)) m")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(CampusTheme.accent)
                .background(CampusTheme.accent.opacity(0.14), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .campusCard(padding: 14)
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 18) {
                    readyGlyph
                    readyCopy
                }

                VStack(alignment: .leading, spacing: 14) {
                    readyGlyph
                    readyCopy
                }
            }

            statusPill
        }
        .frame(maxWidth: .infinity)
        .campusCard(padding: 18)
    }

    private var readyGlyph: some View {
        ZStack {
            ForEach([112.0, 82.0, 54.0], id: \.self) { size in
                Circle()
                    .stroke(CampusTheme.accent.opacity(size < 60 ? 0.9 : 0.14), lineWidth: size < 60 ? 3 : 7)
                    .frame(width: size, height: size)
            }

            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(CampusTheme.accent)
        }
        .frame(width: 118, height: 118)
    }

    private var readyCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready")
                .font(.largeTitle.weight(.semibold))
                .lineLimit(1)
            Text("Tap in at the door. Attendance is marked and the focus shield starts.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CampusTheme.success)
                .frame(width: 30, height: 30)
                .background(CampusTheme.success.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Focus + attendance")
                    .font(.subheadline.weight(.semibold))
                Text(store.hasShieldSelection ? "Custom app selection is active." : "Recommended focus preset is active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            MetricCard(value: store.focusMetricValue, label: store.focusMetricLabel)
            MetricCard(value: "\(store.state.selectedClass.durationMinutes)m", label: "class")
            MetricCard(value: "\(averagePassingMinutes)m", label: "avg pass")
        }
    }
}

private struct FocusActiveView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    lockMark

                    VStack(spacing: 5) {
                        Text("Locked")
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("lock.lockedTitle")
                        Text("Attendance marked")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        MetricCard(value: timing(at: timeline.date).elapsedClock, label: "Focus", dark: true)
                        MetricCard(value: timing(at: timeline.date).remainingClock, label: "Left", dark: true)
                    }

                    allowedCard
                }
                .frame(maxWidth: CampusTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, CampusTheme.screenHorizontalPadding)
                .padding(.top, 28)
                .padding(.bottom, CampusTheme.scrollBottomPadding())
            }
            .background(Color.black)
            .campusFixedAction {
                Button {
                    store.manualUnlock()
                } label: {
                    Label("Unlock", systemImage: "lock.open.fill")
                }
                .buttonStyle(CampusSecondaryButtonStyle())
                .accessibilityIdentifier("lock.unlock")
            }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: store.state.isLocked)
    }

    private var lockMark: some View {
        ZStack {
            ForEach([210.0, 164.0, 120.0], id: \.self) { size in
                Circle()
                    .stroke(.white.opacity(size == 120 ? 0.20 : 0.08), lineWidth: size == 120 ? 6 : 12)
                    .frame(width: size, height: size)
            }
            Circle()
                .fill(.white)
                .frame(width: 108, height: 108)
            Image(systemName: "lock")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.black)
        }
        .frame(height: 222)
    }

    private var allowedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Emergency safe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Phone calls stay available")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func timing(at date: Date) -> SessionTiming {
        guard let activeSession = store.state.activeSession else {
            return SessionTiming(
                session: FocusSession(classSession: store.state.selectedClass, zone: store.state.zone, startedAt: date),
                now: date
            )
        }
        return SessionTiming(session: activeSession, now: date)
    }
}

private struct UnlockedView: View {
    @Environment(CampusLockStore.self) private var store
    var record: AttendanceRecord?

    var body: some View {
        CampusScreen(alignment: .center) {
            successMark
            VStack(spacing: 6) {
                Text("Apps available")
                    .font(.title.weight(.semibold))
                    .accessibilityIdentifier("lock.unlockedTitle")
                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                DetailCard(label: "Session", value: "\(record?.session.title ?? store.state.selectedClass.title) · \(record?.session.durationMinutes ?? store.state.selectedClass.durationMinutes) min")
                DetailCard(label: "Attendance", value: attendanceValue)
            }
        }
        .campusFixedAction {
            Button {
                store.startFocus()
            } label: {
                Label("Start Next Class", systemImage: "arrow.clockwise")
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .accessibilityIdentifier("lock.startNextClass")
        }
    }

    private var successMark: some View {
        Circle()
            .stroke(CampusTheme.success, lineWidth: 5)
            .frame(width: 142, height: 142)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(CampusTheme.success)
            }
    }

    private var attendanceValue: String {
        guard let checkedOutAt = record?.checkedOutAt else { return "Present" }
        return "Present · \(checkedOutAt.formatted(date: .omitted, time: .shortened))"
    }

    private var statusText: String {
        switch record?.state {
        case .checkedOut:
            return "Checked out automatically"
        case .manualUnlock:
            return "Unlocked manually"
        case .present, nil:
            return "Attendance marked"
        }
    }
}

private struct MetricCard: View {
    var value: String
    var label: String
    var dark = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(dark ? Color(.secondarySystemFill) : CampusTheme.elevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct DetailCard: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }
}

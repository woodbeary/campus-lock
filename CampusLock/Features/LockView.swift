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
        .campusLoadIn()
    }
}

private struct ReadyView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: CampusTheme.screenSpacing) {
                    header
                    readyCard(compact: proxy.size.height < 760)
                    statusBlock
                    metricsRow
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: max(0, proxy.size.height - CampusTheme.scrollBottomPadding()), alignment: .top)
                .padding(.horizontal, CampusTheme.screenHorizontalPadding)
                .padding(.top, CampusTheme.screenTopPadding)
                .padding(.bottom, CampusTheme.scrollBottomPadding())
            }
            .contentMargins(.top, 0, for: .scrollContent)
            .background(CampusTheme.background)
        }
        .campusFixedAction {
            Button {
                store.startFocus()
            } label: {
                Label(store.hasShieldSelection ? "Tap In" : "Choose Apps", systemImage: store.hasShieldSelection ? "lock.fill" : "square.grid.3x3.fill")
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .accessibilityIdentifier("lock.startFocus")
        }
    }

    private var averagePassingMinutes: Int {
        max(1, Int((store.metrics.averagePassingSeconds / 60).rounded()))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
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
        .campusCard(padding: 16)
    }

    private func readyCard(compact: Bool) -> some View {
        VStack(spacing: compact ? 14 : 18) {
            ZStack {
                ForEach([compact ? 138.0 : 154.0, compact ? 104.0 : 116.0, compact ? 72.0 : 80.0], id: \.self) { size in
                    Circle()
                        .stroke(CampusTheme.accent.opacity(size < 90 ? 0.95 : 0.14), lineWidth: size < 90 ? 3 : 7)
                        .frame(width: size, height: size)
                }

                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: compact ? 42 : 48, weight: .semibold))
                    .foregroundStyle(CampusTheme.accent)
            }
            .frame(height: compact ? 148 : 168)

            VStack(spacing: 4) {
                Text("Ready")
                    .font(.largeTitle.weight(.semibold))
                    .lineLimit(1)
                Text("Tap in at the door to mark attendance and lock selected apps.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .campusCard(padding: compact ? 18 : 22)
    }

    private var statusBlock: some View {
        HStack(spacing: 12) {
            Image(systemName: store.hasShieldSelection ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(store.hasShieldSelection ? CampusTheme.success : CampusTheme.accent)
                .frame(width: 36, height: 36)
                .background((store.hasShieldSelection ? CampusTheme.success : CampusTheme.accent).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(store.hasShieldSelection ? "Focus + attendance" : "Choose apps first")
                    .font(.headline)
                Text(store.hasShieldSelection ? "Tap once at the classroom door." : "Pick apps before the first lock.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .campusCard(padding: 14)
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            MetricCard(value: "\(store.selectedShieldItemCount)", label: "selected")
            MetricCard(value: "\(store.state.selectedClass.durationMinutes)m", label: "class")
            MetricCard(value: "\(averagePassingMinutes)m", label: "avg pass")
        }
    }
}

private struct FocusActiveView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            GeometryReader { proxy in
                let compact = proxy.size.height < 760
                ScrollView(showsIndicators: false) {
                    VStack(spacing: compact ? 18 : 26) {
                        lockMark(compact: compact)

                        VStack(spacing: 6) {
                            Text("Locked")
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("lock.lockedTitle")
                            Text("Attendance marked")
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            MetricCard(value: timing(at: timeline.date).elapsedClock, label: "Focus", dark: true)
                            MetricCard(value: timing(at: timeline.date).remainingClock, label: "Left", dark: true)
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Allowed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Phone · Messages · Maps")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: max(0, proxy.size.height - CampusTheme.scrollBottomPadding()), alignment: .center)
                    .padding(20)
                    .padding(.top, CampusTheme.screenTopPadding)
                    .padding(.bottom, CampusTheme.scrollBottomPadding())
                }
                .campusFixedAction {
                    Button("Unlock") {
                        store.manualUnlock()
                    }
                    .buttonStyle(CampusSecondaryButtonStyle())
                    .accessibilityIdentifier("lock.unlock")
                }
                .background(Color.black)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func lockMark(compact: Bool) -> some View {
        let rings = compact ? [208.0, 164.0, 120.0] : [250.0, 196.0, 142.0]
        let fill = compact ? 110.0 : 128.0
        return ZStack {
            ForEach(rings, id: \.self) { size in
                Circle()
                    .stroke(.white.opacity(size == rings.last ? 0.20 : 0.08), lineWidth: size == rings.last ? 6 : 12)
                    .frame(width: size, height: size)
            }
            Circle()
                .fill(.white)
                .frame(width: fill, height: fill)
            Image(systemName: "lock")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.black)
        }
        .frame(height: compact ? 220 : 270)
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
        GeometryReader { proxy in
            let compact = proxy.size.height < 760
            ScrollView(showsIndicators: false) {
                VStack(spacing: compact ? 18 : 26) {
                    successMark(compact: compact)
                    VStack(spacing: 6) {
                        Text("Apps available")
                            .font(.title.weight(.semibold))
                            .accessibilityIdentifier("lock.unlockedTitle")
                        Text(statusText)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 12) {
                        DetailCard(label: "Session", value: "\(record?.session.title ?? store.state.selectedClass.title) · \(record?.session.durationMinutes ?? store.state.selectedClass.durationMinutes) min")
                        DetailCard(label: "Attendance", value: attendanceValue)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: max(0, proxy.size.height - CampusTheme.scrollBottomPadding()), alignment: .center)
                .padding(20)
                .padding(.top, CampusTheme.screenTopPadding)
                .padding(.bottom, CampusTheme.scrollBottomPadding())
            }
            .campusFixedAction {
                Button("Start Next Class") {
                    store.startFocus()
                }
                .buttonStyle(CampusPrimaryButtonStyle())
                .accessibilityIdentifier("lock.startNextClass")
            }
        }
    }

    private func successMark(compact: Bool) -> some View {
        Circle()
            .stroke(CampusTheme.success, lineWidth: 5)
            .frame(width: compact ? 142 : 178, height: compact ? 142 : 178)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: compact ? 44 : 52, weight: .bold))
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

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
                VStack(spacing: proxy.size.height < 760 ? 14 : 22) {
                    header
                    startFocusButton(compact: proxy.size.height < 760)
                    statusBlock
                    metricsRow
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: max(0, proxy.size.height - CampusTheme.footerReserve), alignment: .top)
                .padding(.horizontal, CampusTheme.screenHorizontalPadding)
                .padding(.top, CampusTheme.screenTopPadding)
                .padding(.bottom, CampusTheme.footerReserve + 24)
            }
            .contentMargins(.top, 0, for: .scrollContent)
            .background(CampusTheme.background)
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

    private func startFocusButton(compact: Bool) -> some View {
        Button {
            store.startFocus()
        } label: {
            ZStack {
                ForEach([compact ? 166.0 : 190.0, compact ? 126.0 : 146.0, compact ? 92.0 : 104.0], id: \.self) { size in
                    Circle()
                        .stroke(CampusTheme.accent.opacity(size < 110 ? 0.9 : 0.16), lineWidth: size < 110 ? 3 : 7)
                        .frame(width: size, height: size)
                }
                Circle()
                    .fill(.primary)
                    .frame(width: compact ? 96 : 110, height: compact ? 96 : 110)
                VStack(spacing: 1) {
                    Text("Tap")
                        .font(.title3.weight(.semibold))
                    Text("in")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color(.systemBackground))
            }
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 178 : 214)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start Focus")
        .accessibilityIdentifier("lock.startFocus")
    }

    private var statusBlock: some View {
        VStack(spacing: 4) {
            Text(store.hasShieldSelection ? "Focus + attendance" : "Choose apps first")
                .font(.headline)
            Text(store.hasShieldSelection ? "Tap once at the classroom door." : "Pick apps before the first lock.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
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
                    .frame(minHeight: max(0, proxy.size.height - CampusTheme.footerReserve), alignment: .center)
                    .padding(20)
                    .padding(.top, CampusTheme.screenTopPadding)
                    .padding(.bottom, CampusTheme.footerReserve + 28)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CampusBottomBar(footerOffset: CampusTheme.footerReserve) {
                        Button("Unlock") {
                            store.manualUnlock()
                        }
                        .buttonStyle(CampusSecondaryButtonStyle())
                        .accessibilityIdentifier("lock.unlock")
                    }
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
                .frame(minHeight: max(0, proxy.size.height - CampusTheme.footerReserve), alignment: .center)
                .padding(20)
                .padding(.top, CampusTheme.screenTopPadding)
                .padding(.bottom, CampusTheme.footerReserve + 28)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CampusBottomBar(footerOffset: CampusTheme.footerReserve) {
                    Button("Start Next Class") {
                        store.startFocus()
                    }
                    .buttonStyle(CampusPrimaryButtonStyle())
                    .accessibilityIdentifier("lock.startNextClass")
                }
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

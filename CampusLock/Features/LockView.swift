import CampusLockCore
import SwiftUI

struct LockView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.state.isLocked {
                    FocusActiveView()
                } else if case let .unlocked(lastRecord) = store.state.lockState, lastRecord != nil {
                    UnlockedView(record: lastRecord)
                } else {
                    ReadyView()
                }
            }
            .navigationTitle(navigationTitle)
            .background(CampusTheme.background)
        }
    }

    private var navigationTitle: String {
        store.state.isLocked ? "Campus Lock" : "Ready"
    }
}

private struct ReadyView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        VStack(spacing: 26) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.state.selectedClass.title) · \(store.state.selectedClass.room)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(Int(store.state.zone.radiusMeters)) m")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(CampusTheme.accent)
                    .background(CampusTheme.accent.opacity(0.12), in: Capsule())
            }

            Button {
                store.startFocus()
            } label: {
                ZStack {
                    ForEach([210.0, 160.0, 112.0], id: \.self) { size in
                        Circle()
                            .stroke(CampusTheme.accent.opacity(size == 112 ? 0.9 : 0.15), lineWidth: size == 112 ? 3 : 9)
                            .frame(width: size, height: size)
                    }
                    Circle()
                        .fill(.primary)
                        .frame(width: 118, height: 118)
                    VStack(spacing: 1) {
                        Text("Tap")
                            .font(.title2.weight(.semibold))
                        Text("in")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color(.systemBackground))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start Focus")
            .accessibilityIdentifier("lock.startFocus")

            VStack(spacing: 4) {
                Text("Start focus + attendance")
                    .font(.headline)
                Text("One action at the classroom door.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                MetricCard(value: "\(store.state.policy.blockedCategories.count)", label: "groups")
                MetricCard(value: "\(store.state.selectedClass.durationMinutes)m", label: "class")
                MetricCard(value: "4m", label: "pass")
            }

            HStack(spacing: 14) {
                Image(systemName: "lanyardcard")
                    .foregroundStyle(CampusTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(CampusTheme.accent.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Attendance")
                        .font(.headline)
                    Text("Marks present when focus starts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .campusCard()

            Spacer()
        }
        .padding(20)
    }
}

private struct FocusActiveView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 20)
            ZStack {
                ForEach([250.0, 196.0, 142.0], id: \.self) { size in
                    Circle()
                        .stroke(.white.opacity(size == 142 ? 0.20 : 0.08), lineWidth: size == 142 ? 6 : 12)
                        .frame(width: size, height: size)
                }
                Circle()
                    .fill(.white)
                    .frame(width: 128, height: 128)
                Image(systemName: "lock")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.black)
            }
            Text("Locked")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("lock.lockedTitle")
            Text("Attendance marked")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                MetricCard(value: "18:42", label: "Focus", dark: true)
                MetricCard(value: "4:15", label: "Passing", dark: true)
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
            Spacer()
            Button("Unlock") {
                store.manualUnlock()
            }
            .buttonStyle(CampusSecondaryButtonStyle())
            .accessibilityIdentifier("lock.unlock")
        }
        .padding(20)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

private struct UnlockedView: View {
    @Environment(CampusLockStore.self) private var store
    var record: AttendanceRecord?

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 60)
            Circle()
                .stroke(CampusTheme.success, lineWidth: 5)
                .frame(width: 178, height: 178)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(CampusTheme.success)
                }
            Text("Apps available")
                .font(.title.weight(.semibold))
                .accessibilityIdentifier("lock.unlockedTitle")
            Text("Checked out automatically")
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                DetailCard(label: "Session", value: "\(record?.session.title ?? store.state.selectedClass.title) · \(record?.session.durationMinutes ?? store.state.selectedClass.durationMinutes) min")
                DetailCard(label: "Attendance", value: attendanceValue)
            }
            Spacer()
            Button("Start Next Class") {
                store.startFocus()
            }
            .buttonStyle(CampusPrimaryButtonStyle())
        }
        .padding(20)
    }

    private var attendanceValue: String {
        guard let checkedOutAt = record?.checkedOutAt else { return "Present" }
        return "Present · \(checkedOutAt.formatted(date: .omitted, time: .shortened))"
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
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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

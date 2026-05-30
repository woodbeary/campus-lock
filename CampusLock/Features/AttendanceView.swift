import CampusLockCore
import SwiftUI

struct AttendanceView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    activeClassCard
                    HStack(spacing: 12) {
                        Button("Enter") {
                            store.startFocus()
                        }
                        .buttonStyle(CampusPrimaryButtonStyle())
                        Button("Exit") {
                            store.manualUnlock()
                        }
                        .buttonStyle(CampusSecondaryButtonStyle())
                    }
                    scheduleList
                }
                .padding(20)
            }
            .background(CampusTheme.background)
            .navigationTitle("Attendance")
        }
    }

    private var activeClassCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "lanyardcard")
                .font(.title3)
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 48, height: 48)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(store.state.selectedClass.title)
                    .font(.title2.weight(.semibold))
                Text("Period \(store.state.selectedClass.period) · \(store.state.selectedClass.room)")
                    .foregroundStyle(.secondary)
                Text(store.state.isLocked ? "Present" : "Ready")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(store.state.isLocked ? CampusTheme.success : CampusTheme.accent)
                    .background((store.state.isLocked ? CampusTheme.success : CampusTheme.accent).opacity(0.12), in: Capsule())
            }
            Spacer()
        }
        .campusCard()
    }

    private var scheduleList: some View {
        VStack(spacing: 10) {
            ForEach(store.schedule) { classSession in
                Button {
                    store.selectClass(classSession)
                } label: {
                    HStack(spacing: 14) {
                        Text("\(classSession.period)")
                            .font(.caption.weight(.semibold))
                            .frame(width: 30, height: 30)
                            .background(Color(.tertiarySystemGroupedBackground), in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(classSession.title)
                                .font(.headline)
                            Text(classSession.startsAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        status(for: classSession)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .campusCard(padding: 13)
            }
        }
    }

    private func status(for classSession: ClassSession) -> some View {
        let record = store.state.attendanceRecords.last { $0.session.id == classSession.id }
        let label = if store.state.selectedClass.id == classSession.id && store.state.isLocked {
            "Live"
        } else if record != nil {
            "Done"
        } else {
            "Next"
        }
        let color = label == "Live" ? CampusTheme.accent : label == "Done" ? CampusTheme.success : Color.secondary
        return Text(label)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}

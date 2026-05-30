import CampusLockCore
import Combine
import SwiftUI

struct AttendanceView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var confirmation: AttendanceConfirmation?
    @State private var feedbackCount = 0
    @State private var now = Date()
    @State private var settingsIsPresented = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        CampusScreen {
            header
            if let hallPass = store.state.activeHallPass, hallPass.isActive(at: now) {
                HallPassPill(remaining: hallPass.remainingSeconds(at: now))
            }
            scheduleList
        }
        .campusFixedAction {
            bottomAction
        }
        .onReceive(timer) { date in
            now = date
            store.expireHallPassIfNeeded(at: date)
        }
        .sensoryFeedback(.selection, trigger: feedbackCount)
        .alert(confirmationTitle, isPresented: confirmationBinding) {
            confirmationButtons
        }
        .sheet(isPresented: $settingsIsPresented) {
            AppsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Alex")
                .font(.largeTitle.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 0)

            Button {
                settingsIsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CampusTheme.accent)
                    .frame(width: 48, height: 48)
                    .campusGlass(cornerRadius: 24, interactive: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("home.settings")
        }
        .accessibilityIdentifier("home.header")
    }

    @ViewBuilder
    private var bottomAction: some View {
        if store.state.isLocked {
            HStack(spacing: 10) {
                Button {
                    confirmation = store.state.activeHallPass?.isActive(at: now) == true ? .endPass : .hallPass
                } label: {
                    if let hallPass = store.state.activeHallPass, hallPass.isActive(at: now) {
                        Label(passTime(hallPass.remainingSeconds(at: now)), systemImage: "figure.walk")
                    } else {
                        Label("Pass", systemImage: "figure.walk")
                    }
                }
                .campusSecondaryAction()
                .accessibilityIdentifier("attendance.hallPass")

                Button {
                    confirmation = .exit
                } label: {
                    Label("Exit", systemImage: "arrow.up.circle.fill")
                }
                .campusPrimaryAction()
                .accessibilityIdentifier("attendance.exit")
            }
        } else if store.isStartingFocus {
            Button {} label: {
                Label("Locating", systemImage: "location.fill")
            }
            .campusPrimaryAction()
            .disabled(true)
            .accessibilityIdentifier("attendance.locating")
        } else {
            Button {
                confirmation = .enter
            } label: {
                Label("Enter \(store.state.selectedClass.title)", systemImage: "arrow.down.circle.fill")
            }
            .campusPrimaryAction()
            .accessibilityIdentifier("attendance.enter")
        }
    }

    private var scheduleList: some View {
        VStack(spacing: 10) {
            ForEach(store.schedule) { classSession in
                let isSelected = store.state.selectedClass.id == classSession.id
                let hallPassIsActive = isSelected && store.state.activeHallPass?.isActive(at: now) == true
                Button {
                    store.selectClass(classSession)
                } label: {
                    ClassRow(
                        classSession: classSession,
                        isSelected: isSelected,
                        record: store.state.attendanceRecords.last { $0.session.id == classSession.id },
                        isLive: isSelected && store.state.isLocked,
                        isHallPassActive: hallPassIsActive
                    )
                }
                .buttonStyle(.plain)
                .disabled(store.state.isLocked)
            }
        }
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { confirmation != nil },
            set: { isPresented in
                if !isPresented {
                    confirmation = nil
                }
            }
        )
    }

    private var confirmationTitle: String {
        switch confirmation {
        case .enter:
            "Enter \(store.state.selectedClass.title)?"
        case .exit:
            "Exit \(store.state.selectedClass.title)?"
        case .hallPass:
            "Restroom Pass?"
        case .endPass:
            "End Pass?"
        case nil:
            ""
        }
    }

    @ViewBuilder
    private var confirmationButtons: some View {
        Button("Cancel", role: .cancel) {
            confirmation = nil
        }

        switch confirmation {
        case .enter:
            Button("Enter") {
                feedbackCount += 1
                confirmation = nil
                store.startFocus()
            }
        case .exit:
            Button("Exit", role: .destructive) {
                feedbackCount += 1
                store.manualUnlock()
                confirmation = nil
            }
        case .hallPass:
            Button("Start") {
                feedbackCount += 1
                store.startHallPass()
                confirmation = nil
            }
        case .endPass:
            Button("End") {
                feedbackCount += 1
                store.endHallPass()
                confirmation = nil
            }
        case nil:
            EmptyView()
        }
    }

    private func passTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.up)))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}

private enum AttendanceConfirmation {
    case enter
    case exit
    case hallPass
    case endPass
}

private struct HallPassPill: View {
    var remaining: TimeInterval

    var body: some View {
        Label("Restroom \(passTime)", systemImage: "figure.walk")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(CampusTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .campusGlass(cornerRadius: 18, interactive: true)
            .accessibilityIdentifier("attendance.hallPass.status")
    }

    private var passTime: String {
        let totalSeconds = max(0, Int(remaining.rounded(.up)))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }
}

private struct ClassRow: View {
    var classSession: ClassSession
    var isSelected: Bool
    var record: AttendanceRecord?
    var isLive: Bool
    var isHallPassActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(classSession.period)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? CampusTheme.accent : Color(.tertiarySystemGroupedBackground), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(classSession.title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("\(classSession.startsAt.formatted(date: .omitted, time: .shortened)) · \(classSession.room)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
            statusBadge
        }
        .contentShape(Rectangle())
        .campusCard(padding: 14)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? CampusTheme.accent : .clear, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(isSelected ? "attendance.class.selected" : "attendance.class")
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isHallPassActive {
            Badge(title: "Pass", color: CampusTheme.accent, symbol: "figure.walk")
        } else if isLive {
            Badge(title: "Present", color: CampusTheme.success, symbol: "checkmark.circle.fill")
        } else if record != nil {
            Badge(title: "Done", color: CampusTheme.success, symbol: "checkmark")
        } else if isSelected {
            Badge(title: "Selected", color: CampusTheme.accent, symbol: "circle.fill")
        }
    }
}

private struct Badge: View {
    var title: String
    var color: Color
    var symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}

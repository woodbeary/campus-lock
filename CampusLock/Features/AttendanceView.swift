import CampusLockCore
import Combine
import Foundation
import SwiftUI

struct AttendanceView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var confirmation: AttendanceConfirmation?
    @State private var feedbackCount = 0
    @State private var now = Date()
    @State private var settingsIsPresented = false
    @State private var nfcEntryIsPresented = false
    @State private var shouldShowManualFallbackAfterNFC = false
    @State private var nfcTimeoutTask: Task<Void, Never>?
    @State private var nfcManualFallbackTask: Task<Void, Never>?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        CampusScreen(background: screenBackground) {
            header
            activeLockPanel
            if let hallPass = store.state.activeHallPass, hallPass.isActive(at: now) {
                HallPassPill(remaining: hallPass.remainingSeconds(at: now))
            }
            scheduleList
        }
        .campusFixedAction(background: screenBackground) {
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
        .sheet(isPresented: $nfcEntryIsPresented, onDismiss: {
            cancelNFCFallbackTimeout()
            shouldShowManualFallbackAfterNFC = false
            store.cancelNFCEntryScan()
        }) {
            NFCEntrySheet(delaysManualFallback: isUITesting) {
                feedbackCount += 1
                cancelNFCFallbackTimeout()
                shouldShowManualFallbackAfterNFC = false
                nfcEntryIsPresented = false
                store.enterManuallyFromNFCSheet()
            } onCancel: {
                cancelNFCFallbackTimeout()
                shouldShowManualFallbackAfterNFC = false
                nfcEntryIsPresented = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: store.state.isLocked) { _, isLocked in
            if isLocked {
                cancelNFCFallbackTimeout()
                shouldShowManualFallbackAfterNFC = false
                nfcEntryIsPresented = false
            }
        }
        .onChange(of: store.isStartingFocus) { _, isStartingFocus in
            if isStartingFocus {
                cancelNFCFallbackTimeout()
                shouldShowManualFallbackAfterNFC = false
                nfcEntryIsPresented = false
            }
        }
        .onChange(of: store.nfcScanState) { _, state in
            handleNFCScanState(state)
        }
        .sheet(isPresented: $settingsIsPresented) {
            AppsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(store.state.isLocked ? .dark : nil)
        .animation(.snappy(duration: 0.28), value: store.state.isLocked)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Alex")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(store.state.isLocked ? .white : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Button {
                settingsIsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(store.state.isLocked ? .white : CampusTheme.accent)
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
    private var activeLockPanel: some View {
        if let activeSession = store.state.activeSession {
            let timing = SessionTiming(session: activeSession, now: now)
            let isLocked = store.state.isLocked
            let isOutside = store.state.isOutsideActiveZone
            let accentColor = isOutside ? CampusTheme.warning : Color.white
            let primaryTextColor = isLocked ? Color.white : Color.primary
            let secondaryTextColor = isLocked ? Color.white.opacity(0.66) : Color.secondary
            VStack(spacing: 14) {
                ZStack {
                    ForEach([138.0, 96.0, 58.0], id: \.self) { size in
                        Circle()
                            .stroke(accentColor.opacity(size == 58 ? 0.32 : 0.12), lineWidth: size == 58 ? 5 : 10)
                            .frame(width: size, height: size)
                    }

                    Image(systemName: isLocked ? "lock.fill" : "location.slash.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(isLocked ? Color.black : Color.white)
                        .frame(width: 66, height: 66)
                        .background(isLocked ? Color.white : CampusTheme.warning, in: Circle())
                }
                .frame(height: 146)

                VStack(spacing: 6) {
                    Text(timing.elapsedClock)
                        .font(.system(size: 58, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .accessibilityIdentifier("attendance.active.elapsed")

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            activeStatusLabel(isOutside: isOutside)
                            Text("·")
                            Text(averageSessionText)
                                .monospacedDigit()
                                .accessibilityIdentifier("attendance.active.average")
                            if isOutside {
                                Text("·")
                                Text(outsideDistanceText)
                                    .monospacedDigit()
                                    .accessibilityIdentifier("attendance.active.outsideDistance")
                            }
                        }

                        VStack(spacing: 3) {
                            activeStatusLabel(isOutside: isOutside)
                            HStack(spacing: 8) {
                                Text(averageSessionText)
                                    .monospacedDigit()
                                    .accessibilityIdentifier("attendance.active.average")
                                if isOutside {
                                    Text("·")
                                    Text(outsideDistanceText)
                                        .monospacedDigit()
                                        .accessibilityIdentifier("attendance.active.outsideDistance")
                                }
                            }
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(secondaryTextColor)
                    .accessibilityIdentifier("attendance.active.status")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 18)
            .background(isLocked ? Color.white.opacity(0.08) : CampusTheme.elevated.opacity(0.74), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(isLocked ? Color.white.opacity(0.10) : CampusTheme.warning.opacity(0.26), lineWidth: 1)
            }
            .accessibilityIdentifier("attendance.active.panel")
        }
    }

    private func activeStatusLabel(isOutside: Bool) -> some View {
        Label(isOutside ? "Outside" : "Active", systemImage: isOutside ? "location.slash.fill" : "circle.fill")
            .labelStyle(.titleAndIcon)
            .accessibilityIdentifier(isOutside ? "attendance.zone.outside" : "attendance.zone.inside")
    }

    @ViewBuilder
    private var bottomAction: some View {
        if store.state.activeSession != nil {
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
            } else {
                HStack(spacing: 10) {
                    Button {} label: {
                        Label(outsideDistanceText, systemImage: "location.slash.fill")
                    }
                    .campusSecondaryAction()
                    .disabled(true)
                    .accessibilityIdentifier("attendance.outside.status")

                    Button {
                        confirmation = .exit
                    } label: {
                        Label("Exit", systemImage: "arrow.up.circle.fill")
                    }
                    .campusPrimaryAction()
                    .accessibilityIdentifier("attendance.exit")
                }
            }
        } else if store.isStartingFocus {
            Button {} label: {
                Label("Locating", systemImage: "location.fill")
            }
            .campusPrimaryAction()
            .disabled(true)
            .accessibilityIdentifier("attendance.locating")
        } else if selectedClassHasCompletedRecordToday {
            Button {} label: {
                Label("Done", systemImage: "checkmark.circle.fill")
            }
            .campusPrimaryAction()
            .disabled(true)
            .accessibilityIdentifier("attendance.done")
        } else {
            Button {
                startNFCEntry()
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
                        record: recordToday(for: classSession),
                        isLive: isSelected && store.state.activeSession != nil,
                        isHallPassActive: hallPassIsActive,
                        isOutsideZone: isSelected && store.state.isOutsideActiveZone
                    )
                }
                .buttonStyle(.plain)
                .disabled(store.state.activeSession != nil)
            }
        }
    }

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    private var screenBackground: Color {
        store.state.isLocked ? .black : CampusTheme.background
    }

    private func startNFCEntry() {
        cancelNFCFallbackTimeout()
        shouldShowManualFallbackAfterNFC = true
        store.startNFCEntryScan()
        if isUITesting {
            nfcEntryIsPresented = true
        } else {
            scheduleNativeNFCTimeout()
        }
    }

    private func handleNFCScanState(_ state: NFCScanState) {
        guard shouldShowManualFallbackAfterNFC else { return }

        switch state {
        case .scanning:
            break
        case .detected:
            cancelNFCFallbackTimeout()
            shouldShowManualFallbackAfterNFC = false
            nfcEntryIsPresented = false
        case .idle, .unavailable, .failed:
            cancelNFCFallbackTimeout()
            presentManualFallbackAfterNativeScan(delay: state == .idle ? .milliseconds(250) : .zero)
        }
    }

    private func scheduleNativeNFCTimeout() {
        nfcTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard
                !Task.isCancelled,
                shouldShowManualFallbackAfterNFC,
                store.state.activeSession == nil,
                !store.isStartingFocus,
                store.nfcScanState == .scanning
            else {
                return
            }
            store.cancelNFCEntryScan()
            presentManualFallbackAfterNativeScan(delay: .milliseconds(250))
        }
    }

    private func cancelNFCFallbackTimeout() {
        nfcTimeoutTask?.cancel()
        nfcTimeoutTask = nil
        nfcManualFallbackTask?.cancel()
        nfcManualFallbackTask = nil
    }

    private func presentManualFallbackAfterNativeScan(delay: Duration) {
        guard !nfcEntryIsPresented else { return }

        nfcManualFallbackTask?.cancel()
        nfcManualFallbackTask = Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard
                !Task.isCancelled,
                shouldShowManualFallbackAfterNFC,
                store.state.activeSession == nil,
                !store.isStartingFocus,
                store.nfcScanState != .scanning,
                store.nfcScanState != .detected
            else {
                return
            }
            shouldShowManualFallbackAfterNFC = false
            nfcEntryIsPresented = true
            nfcManualFallbackTask = nil
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

    private var selectedClassHasCompletedRecordToday: Bool {
        recordToday(for: store.state.selectedClass)?.checkedOutAt != nil
    }

    private func recordToday(for classSession: ClassSession) -> AttendanceRecord? {
        store.state.attendanceRecords.last { record in
            record.session.id == classSession.id
                && Calendar.current.isDate(record.checkedInAt, inSameDayAs: now)
        }
    }

    private var averageSessionText: String {
        let durations = store.state.attendanceRecords.compactMap { record -> TimeInterval? in
            guard let checkedOutAt = record.checkedOutAt else { return nil }
            return max(0, checkedOutAt.timeIntervalSince(record.checkedInAt))
        }
        guard !durations.isEmpty else { return "Avg —" }
        let average = durations.reduce(0, +) / Double(durations.count)
        return "Avg \(SessionTiming.clock(average))"
    }

    private var outsideDistanceText: String {
        guard let meters = store.state.outsideDistanceMeters else { return "Outside" }
        let feet = meters * 3.28084
        if feet < 1_000 {
            return "\(max(1, Int(feet.rounded()))) ft out"
        }
        return String(format: "%.1f mi out", feet / 5_280)
    }
}

private enum AttendanceConfirmation {
    case exit
    case hallPass
    case endPass
}

private struct NFCEntrySheet: View {
    @Environment(CampusLockStore.self) private var store
    @State private var hasWaitedForTag = false
    @State private var manualFallbackIsVisible = false
    var delaysManualFallback: Bool
    var onManualEnter: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .campusGlass(cornerRadius: 18, interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("attendance.nfc.cancel")
            }

            Spacer(minLength: 8)

            VStack(spacing: 20) {
                NFCGlyph(mode: glyphMode, isScanning: scanAnimationIsActive)
                VStack(spacing: 6) {
                    Text(store.state.selectedClass.title)
                        .font(.title2.weight(.semibold))
                        .lineLimit(1)
                    Text(statusText ?? " ")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .opacity(statusText == nil ? 0 : 1)
                        .contentTransition(.opacity)
                        .accessibilityHidden(statusText == nil)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("attendance.nfcSheet")

            Spacer(minLength: 24)

            Group {
                if manualFallbackIsVisible {
                    Button {
                        onManualEnter()
                    } label: {
                        Label("Enter", systemImage: "checkmark.circle.fill")
                    }
                    .campusPrimaryAction()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .accessibilityIdentifier("attendance.nfc.manualEnter")
                } else {
                    Color.clear
                        .frame(height: 54)
                        .accessibilityHidden(true)
                }
            }
            .animation(.snappy(duration: 0.22), value: manualFallbackIsVisible)
        }
        .padding(.horizontal, CampusTheme.screenHorizontalPadding)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(CampusTheme.background.ignoresSafeArea())
        .task {
            hasWaitedForTag = false
            manualFallbackIsVisible = false
            if delaysManualFallback {
                try? await Task.sleep(for: fallbackDelay)
            }
            guard !Task.isCancelled, store.state.activeSession == nil, store.nfcScanState != .detected else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                hasWaitedForTag = true
                manualFallbackIsVisible = true
            }
        }
        .onChange(of: store.nfcScanState) { _, state in
            switch state {
            case .scanning, .unavailable, .failed:
                break
            default:
                hasWaitedForTag = false
                manualFallbackIsVisible = false
            }
        }
    }

    private var statusText: String? {
        guard hasWaitedForTag else { return nil }

        if store.nfcScanState.isScanning {
            return "Still searching…"
        } else {
            return store.nfcScanState.fallbackText
        }
    }

    private var scanAnimationIsActive: Bool {
        store.nfcScanState.isScanning || !hasWaitedForTag
    }

    private var glyphMode: NFCGlyphMode {
        manualFallbackIsVisible && !store.nfcScanState.isScanning ? .manual : .scan
    }

    private var fallbackDelay: Duration {
        ProcessInfo.processInfo.arguments.contains("--ui-testing") ? .milliseconds(650) : .seconds(4)
    }
}

private enum NFCGlyphMode {
    case scan
    case manual

    var systemImage: String {
        switch self {
        case .scan:
            "wave.3.right.circle.fill"
        case .manual:
            "checkmark.circle.fill"
        }
    }
}

private struct NFCGlyph: View {
    var mode: NFCGlyphMode
    var isScanning: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach([132.0, 96.0, 62.0], id: \.self) { size in
                Circle()
                    .stroke(CampusTheme.accent.opacity(size == 62 ? 0.28 : 0.12), lineWidth: size == 62 ? 4 : 8)
                    .frame(width: size, height: size)
                    .scaleEffect(isScanning && pulse ? 1.06 : 0.96)
                    .opacity(isScanning || mode == .manual ? 1 : 0.65)
            }

            Image(systemName: mode.systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(mode == .manual ? CampusTheme.success : CampusTheme.accent)
                .symbolEffect(.pulse, options: .repeating, value: isScanning)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 150, height: 150)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
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
    var isOutsideZone: Bool

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
        } else if isOutsideZone {
            Badge(title: "Outside", color: CampusTheme.warning, symbol: "location.slash.fill")
        } else if isLive {
            Badge(title: "Active", color: CampusTheme.success, symbol: "lock.fill")
        } else if record?.checkedOutAt != nil {
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

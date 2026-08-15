import CampusLockCore
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct SetupView: View {
    @Environment(CampusLockStore.self) private var store
    @FocusState private var focusedField: OnboardingField?
    @State private var step: OnboardingStep = .name
    @State private var draftName = ""
    @State private var schoolQuery = ""
    @State private var schoolResults = SchoolSearchService.suggestedSchools
    @State private var selectedSchool: CampusSchoolSelection?
    @State private var isSearchingSchools = false
    @State private var schoolSearchTask: Task<Void, Never>?
    @State private var feedbackTick = 0

    var body: some View {
        @Bindable var store = store
        CampusScreen(alignment: .center) {
            progressHeader
            stepContent
                .id(step)
                .transition(.opacity.combined(with: .offset(y: 8)))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .campusFixedAction {
            bottomAction
        }
        .background(CampusTheme.background.ignoresSafeArea())
        .task {
            configureInitialState()
            if store.state.currentLocation == nil, store.locationStatus.isUsable {
                await store.requestLocationRefresh()
            }
        }
        .onChange(of: schoolQuery) { _, query in
            if selectedSchool?.name != query {
                selectedSchool = nil
            }
            scheduleSchoolSearch(for: query)
        }
        .sensoryFeedback(.selection, trigger: step)
        .sensoryFeedback(.success, trigger: feedbackTick)
        .animation(.snappy(duration: 0.24), value: step)
        .animation(.snappy(duration: 0.2), value: selectedSchool)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $store.isShowingAppPicker, selection: $store.activitySelection)
        #endif
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(CampusTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(CampusTheme.accent.opacity(0.12), in: Circle())

                Text("Campus Lock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Text(step.badge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }

            ProgressView(value: Double(step.index + 1), total: Double(OnboardingStep.allCases.count))
                .tint(CampusTheme.accent)
                .controlSize(.small)
                .accessibilityIdentifier("setup.progress")
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("setup.header")
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name:
            nameStep
        case .school:
            schoolStep
        case .screenTime:
            permissionStep(
                title: "Hide apps",
                detail: store.screenTimeReady ? "Allowed" : "Permission",
                symbol: "lock.app.dashed",
                isDone: store.screenTimeReady
            )
            .accessibilityIdentifier("setup.screenTime")
        case .apps:
            appsStep
        case .location:
            permissionStep(
                title: "Find campus",
                detail: store.locationStatus.isUsable ? "Allowed" : "Permission",
                symbol: "location.circle",
                isDone: store.locationStatus.isUsable
            )
            .accessibilityIdentifier("setup.location")
        case .nfc:
            permissionStep(
                title: "Tap in",
                detail: "Manual backup",
                symbol: "wave.3.right.circle",
                isDone: false
            )
            .accessibilityIdentifier("setup.nfc")
        case .zone:
            zoneStep
        }
    }

    private var nameStep: some View {
        VStack(spacing: 18) {
            OnboardingPrompt(
                symbol: "person.crop.circle",
                title: "Your name"
            )

            TextField("First name", text: $draftName)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { continueIfPossible() }
                .padding(18)
                .background(CampusTheme.elevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
                }
                .accessibilityIdentifier("setup.name")
        }
        .frame(maxWidth: .infinity)
        .campusCard(padding: 16)
    }

    private var schoolStep: some View {
        VStack(spacing: 16) {
            OnboardingPrompt(
                symbol: "building.columns",
                title: "Your campus"
            )

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search Orange County schools", text: $schoolQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .school)
                    .submitLabel(.search)
                    .onSubmit { scheduleSchoolSearch(for: schoolQuery, debounce: false) }
                    .accessibilityIdentifier("setup.school.search")
                if isSearchingSchools {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(14)
            .background(CampusTheme.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 8) {
                ForEach(schoolResults) { school in
                    SchoolResultRow(
                        school: school,
                        isSelected: selectedSchool == school
                    ) {
                        selectedSchool = school
                        schoolQuery = school.name
                        focusedField = nil
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .campusCard(padding: 12)
        .accessibilityIdentifier("setup.school")
    }

    private var appsStep: some View {
        VStack(spacing: 12) {
            OnboardingStatusPanel(
                title: "Hidden apps",
                detail: "Default focus list",
                symbol: "slider.horizontal.3",
                isDone: true
            )

            Button {
                Task { await store.openAppPicker() }
            } label: {
                Label("Customize", systemImage: "square.grid.2x2")
            }
            .campusSecondaryAction()
            .accessibilityIdentifier("setup.apps.customize")
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("setup.apps")
    }

    private func permissionStep(
        title: String,
        detail: String,
        symbol: String,
        isDone: Bool
    ) -> some View {
        OnboardingStatusPanel(
            title: title,
            detail: detail,
            symbol: symbol,
            isDone: isDone
        )
    }

    private var zoneStep: some View {
        VStack(spacing: 14) {
            if let currentLocation = store.state.currentLocation {
                OnboardingPrompt(
                    symbol: "circle.dashed",
                    title: "Class radius"
                )

                ZoneMapCard(center: currentLocation, radius: store.state.zone.radiusMeters)
                    .frame(maxHeight: 380)
                    .padding(.horizontal, -12)
                    .accessibilityIdentifier("setup.zone.map")
            } else {
                OnboardingStatusPanel(
                    title: "Class radius",
                    detail: store.isLocating ? "Finding location" : "Use location",
                    symbol: store.isLocating ? "location.magnifyingglass" : "location.circle",
                    isDone: false
                )
                .accessibilityIdentifier("setup.zone.location")
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Radius")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(store.state.zone.radiusMeters)) m")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Slider(
                    value: Binding(
                        get: { store.state.zone.radiusMeters },
                        set: { store.updateRadius($0) }
                    ),
                    in: 50...500,
                    step: 10
                )
                .accessibilityIdentifier("setup.zone.radius")
            }
            .campusCard(padding: 12)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("setup.zone")
    }

    private var bottomAction: some View {
        Button {
            handlePrimaryAction()
        } label: {
            Label(primaryActionTitle, systemImage: primaryActionSymbol)
        }
        .campusPrimaryAction()
        .disabled(!primaryActionIsEnabled)
        .opacity(primaryActionIsEnabled ? 1 : 0.36)
        .accessibilityIdentifier("setup.continue")
    }

    private var primaryActionTitle: String {
        switch step {
        case .screenTime where !store.screenTimeReady:
            "Allow App Lock"
        case .location where !store.locationStatus.isUsable:
            locationPermissionTitle
        case .zone where store.state.currentLocation == nil:
            store.isLocating ? "Finding" : "Use Current Location"
        case .zone:
            "Finish"
        default:
            "Continue"
        }
    }

    private var primaryActionSymbol: String {
        switch step {
        case .screenTime where !store.screenTimeReady:
            "lock.shield"
        case .location where !store.locationStatus.isUsable:
            "location.fill"
        case .zone where store.state.currentLocation == nil:
            store.isLocating ? "location.magnifyingglass" : "location.fill"
        case .zone:
            "checkmark"
        default:
            "arrow.right"
        }
    }

    private var primaryActionIsEnabled: Bool {
        switch step {
        case .name:
            !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .school:
            selectedSchool != nil
        case .zone where store.state.currentLocation == nil:
            !store.isLocating
        default:
            true
        }
    }

    private var locationPermissionTitle: String {
        if case let .denied(message) = store.locationStatus, message == "Location denied" {
            return "Settings"
        }
        return store.locationStatus.label == "Allow Always" ? "Allow Always" : "Allow Location"
    }

    private func handlePrimaryAction() {
        switch step {
        case .name:
            store.updateDisplayName(draftName)
            advance(to: .school)
        case .school:
            guard let selectedSchool else { return }
            store.selectSchool(selectedSchool)
            advance(to: .screenTime)
        case .screenTime:
            guard !store.screenTimeReady else {
                advance(to: .apps)
                return
            }
            Task {
                let isApproved = await store.requestScreenTimeAuthorization()
                if isApproved {
                    advance(to: .apps)
                }
            }
        case .apps:
            advance(to: .location)
        case .location:
            guard !store.locationStatus.isUsable else {
                advance(to: .nfc)
                return
            }
            if case let .denied(message) = store.locationStatus, message == "Location denied" {
                store.openSystemSettings()
            } else {
                Task {
                    let isApproved = await store.requestLocationRefresh()
                    if isApproved {
                        advance(to: .nfc)
                    }
                }
            }
        case .nfc:
            advance(to: .zone)
        case .zone:
            Task {
                if store.state.currentLocation == nil {
                    _ = await store.requestLocationRefresh()
                } else if store.finishZoneSetup() {
                    feedbackTick += 1
                }
            }
        }
    }

    private func continueIfPossible() {
        guard primaryActionIsEnabled else { return }
        handlePrimaryAction()
    }

    private func configureInitialState() {
        draftName = store.state.profile.displayName
        selectedSchool = store.state.profile.school
        schoolQuery = store.state.profile.school?.name ?? ""
        if let selectedSchool {
            schoolResults = [selectedSchool]
        }
        step = firstIncompleteStep
    }

    private var firstIncompleteStep: OnboardingStep {
        if !store.state.profile.hasDisplayName { return .name }
        if !store.state.profile.hasSchool { return .school }
        return .screenTime
    }

    private func advance(to nextStep: OnboardingStep) {
        focusedField = nil
        withAnimation(.snappy(duration: 0.24)) {
            step = nextStep
        }
    }

    private func scheduleSchoolSearch(for query: String, debounce: Bool = true) {
        schoolSearchTask?.cancel()
        schoolSearchTask = Task { @MainActor in
            if debounce {
                try? await Task.sleep(for: .milliseconds(280))
            }
            guard !Task.isCancelled else { return }
            isSearchingSchools = true
            let results = await SchoolSearchService.searchSchools(matching: query)
            guard !Task.isCancelled else { return }
            schoolResults = results
            isSearchingSchools = false
        }
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case name
    case school
    case screenTime
    case apps
    case location
    case nfc
    case zone

    var index: Int { rawValue }

    var badge: String {
        switch self {
        case .name: "Profile"
        case .school: "Campus"
        case .screenTime: "Lock"
        case .apps: "Apps"
        case .location: "Location"
        case .nfc: "Tap"
        case .zone: "Zone"
        }
    }

    var symbol: String {
        switch self {
        case .name: "person.crop.circle"
        case .school: "building.columns"
        case .screenTime: "lock.app.dashed"
        case .apps: "slider.horizontal.3"
        case .location: "location.circle"
        case .nfc: "wave.3.right.circle"
        case .zone: "circle.dashed"
        }
    }
}

private enum OnboardingField: Hashable {
    case name
    case school
}

private struct OnboardingPrompt: View {
    var symbol: String
    var title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 70, height: 70)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.7), lineWidth: 1)
                }

            Text(title)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingStatusPanel: View {
    var title: String
    var detail: String
    var symbol: String
    var isDone: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach([132.0, 94.0], id: \.self) { size in
                    Circle()
                        .stroke((isDone ? CampusTheme.success : CampusTheme.accent).opacity(size == 132 ? 0.08 : 0.14), lineWidth: 10)
                        .frame(width: size, height: size)
                }

                Image(systemName: isDone ? "checkmark" : symbol)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(isDone ? CampusTheme.success : CampusTheme.accent)
                    .symbolEffect(.pulse, value: !isDone)
                    .frame(width: 78, height: 78)
                    .background((isDone ? CampusTheme.success : CampusTheme.accent).opacity(0.12), in: Circle())
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(detail)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .campusCard(padding: 22)
        .accessibilityElement(children: .combine)
    }
}

private struct SchoolResultRow: View {
    var school: CampusSchoolSelection
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "building.columns")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isSelected ? CampusTheme.success : CampusTheme.accent)
                    .frame(width: 34, height: 34)
                    .background((isSelected ? CampusTheme.success : CampusTheme.accent).opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(school.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !school.address.isEmpty {
                        Text(school.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                isSelected ? CampusTheme.accent.opacity(0.1) : Color(.tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? CampusTheme.accent.opacity(0.34) : Color.clear, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("setup.school.result")
    }
}

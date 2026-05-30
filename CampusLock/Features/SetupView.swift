import SwiftUI

struct SetupView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)
            CampusGlassGroup(spacing: 22) {
                VStack(spacing: 22) {
                    header
                    currentPermissionCard
                }
            }
            .frame(maxWidth: CampusTheme.contentMaxWidth)
            .padding(.horizontal, CampusTheme.screenHorizontalPadding)
            Spacer(minLength: 96)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CampusTheme.background.ignoresSafeArea())
        .campusFixedAction {
            bottomAction
        }
        .animation(.snappy(duration: 0.22), value: store.screenTimeReady)
        .animation(.snappy(duration: 0.22), value: store.locationStatus)
        .animation(.snappy(duration: 0.22), value: store.isLocating)
        .sensoryFeedback(.success, trigger: store.canContinuePermissionOnboarding)
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 96, height: 96)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
                .campusGlass(cornerRadius: 48, interactive: true)

            VStack(spacing: 8) {
                Text("Campus Lock")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("setup.hero")
    }

    @ViewBuilder
    private var currentPermissionCard: some View {
        if !store.screenTimeReady {
            PermissionStepCard(
                symbol: "lock.app.dashed",
                title: "Screen Time",
                status: setupStatus(store.authorizationStatus, ready: store.screenTimeReady),
                actionTitle: actionTitle(for: store.authorizationStatus)
            ) {
                handlePermissionAction(store.authorizationStatus) {
                    await store.requestScreenTimeAuthorization()
                }
            }
            .accessibilityIdentifier("setup.screenTime")
        } else if !store.locationStatus.isUsable {
            PermissionStepCard(
                symbol: "location.circle",
                title: "Location",
                status: setupStatus(store.locationStatus, ready: store.locationStatus.isUsable),
                actionTitle: store.isLocating ? "Waiting" : actionTitle(for: store.locationStatus)
            ) {
                handlePermissionAction(store.locationStatus) {
                    await store.requestLocationRefresh()
                }
            }
            .accessibilityIdentifier("setup.location")
        } else {
            PermissionStepCard(
                symbol: "checkmark.circle",
                title: "Ready",
                status: "Ready",
                actionTitle: nil
            )
            .accessibilityIdentifier("setup.ready")
        }
    }

    private var bottomAction: some View {
        Button {
            store.confirmPermissionOnboarding()
        } label: {
            Label("Continue", systemImage: "arrow.right")
        }
        .campusPrimaryAction()
        .disabled(!store.canContinuePermissionOnboarding)
        .opacity(store.canContinuePermissionOnboarding ? 1 : 0.36)
        .accessibilityIdentifier("setup.continue")
    }

    private func setupStatus(_ status: PermissionStatus, ready: Bool) -> String {
        if ready { return "Ready" }
        switch status {
        case .notDetermined:
            return "Allow"
        case let .denied(message):
            return message == "Allow Always" ? "Always" : "Denied"
        case .approved:
            return "Ready"
        }
    }

    private func actionTitle(for status: PermissionStatus) -> String {
        switch status {
        case .notDetermined, .approved:
            return "Allow"
        case let .denied(message):
            return message == "Allow Always" ? "Allow" : "Settings"
        }
    }

    private func handlePermissionAction(
        _ status: PermissionStatus,
        request: @escaping () async -> Bool
    ) {
        if case let .denied(message) = status, message != "Allow Always" {
            store.openSystemSettings()
        } else {
            Task { _ = await request() }
        }
    }
}

private struct PermissionStepCard: View {
    var symbol: String
    var title: String
    var status: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(CampusTheme.accent)
                    .frame(width: 54, height: 54)
                    .background(CampusTheme.accent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Label(status, systemImage: status == "Ready" ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status == "Ready" ? CampusTheme.success : .secondary)

                Spacer(minLength: 0)

                if let actionTitle, let action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .disabled(actionTitle == "Waiting")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }
}

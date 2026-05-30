import CampusLockCore
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppsView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store
        CampusScreen {
            CampusScreenHeader(
                title: "Apps",
                subtitle: "Choose what disappears during focus.",
                symbol: "square.grid.3x3"
            )
            selectedSummary
            recommendedPresetCard
            permissionCard
            nativePickerCard
            allowedSummary
        }
        .campusFixedAction {
            nativePickerButton
        }
        .sensoryFeedback(.selection, trigger: store.isShowingAppPicker)
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $store.isShowingAppPicker, selection: $store.activitySelection)
        #endif
    }

    private var selectedSummary: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CampusTheme.accent.opacity(0.12))
                Image(systemName: "app.badge.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CampusTheme.accent)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.hasShieldSelection ? "\(store.selectedShieldItemCount)" : "Preset")
                    .font(.largeTitle.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(store.hasShieldSelection ? "selected" : "recommended")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }

    private var nativePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apple App Picker")
                .font(.headline)
            Text("Opens Apple’s private Screen Time picker with real apps, categories, and websites from this iPhone.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }

    private var permissionCard: some View {
        HStack(spacing: 14) {
            Image(systemName: store.screenTimeReady ? "checkmark.shield.fill" : "lock.shield")
                .font(.headline.weight(.semibold))
                .foregroundStyle(store.screenTimeReady ? CampusTheme.success : CampusTheme.accent)
                .frame(width: 40, height: 40)
                .background((store.screenTimeReady ? CampusTheme.success : CampusTheme.accent).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Screen Time Permission")
                    .font(.headline)
                Text(store.screenTimeReady ? "Ready for focus controls" : "Required before Apple can show apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .campusCard(padding: 14)
    }

    private var recommendedPresetCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 40, height: 40)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Recommended Focus")
                    .font(.headline)
                Text("Default shields every app and website category Apple allows Campus Lock to control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: store.hasShieldSelection ? "circle" : "checkmark")
                .font(.headline)
                .foregroundStyle(store.hasShieldSelection ? .secondary : CampusTheme.success)
        }
        .campusCard(padding: 14)
    }

    private var nativePickerButton: some View {
        Button {
            Task {
                await store.openAppPicker()
            }
        } label: {
            Label(store.screenTimeReady ? "Customize Apps" : "Allow Screen Time", systemImage: store.screenTimeReady ? "slider.horizontal.3" : "lock.shield")
        }
        .buttonStyle(CampusPrimaryButtonStyle())
        .accessibilityIdentifier("apps.chooseSpecific")
    }

    private var allowedSummary: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.shield")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CampusTheme.success)
                .frame(width: 40, height: 40)
                .background(CampusTheme.success.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Emergency safe")
                    .font(.headline)
                Text("Phone calls stay available by iOS. Customize exceptions anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .campusCard(padding: 14)
    }
}

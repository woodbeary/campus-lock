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
                Text("\(store.selectedShieldItemCount)")
                    .font(.largeTitle.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("selected")
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
            Text("Apple Screen Time")
                .font(.headline)
            Text("Uses Family Controls so real apps, categories, and websites are shielded during focus.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }

    private var nativePickerButton: some View {
        Button {
            store.isShowingAppPicker = true
        } label: {
            Label("Choose Apps", systemImage: "slider.horizontal.3")
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
                Text("Always available")
                    .font(.headline)
                Text("Phone · Messages · Maps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .campusCard(padding: 14)
    }
}

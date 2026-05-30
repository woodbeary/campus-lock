import CampusLockCore
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppsView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: CampusTheme.screenSpacing) {
                CampusScreenHeader(
                    title: "Apps",
                    subtitle: "Choose what disappears during focus.",
                    symbol: "square.grid.3x3"
                )
                selectedSummary
                allowedSummary
            }
            .padding(.horizontal, CampusTheme.screenHorizontalPadding)
            .padding(.top, CampusTheme.screenTopPadding)
            .padding(.bottom, CampusTheme.scrollBottomPadding())
            .campusLoadIn()
        }
        .background(CampusTheme.background)
        .campusFixedAction {
            nativePickerButton
        }
        .sensoryFeedback(.selection, trigger: store.isShowingAppPicker)
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $store.isShowingAppPicker, selection: $store.activitySelection)
        #endif
    }

    private var selectedSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(store.selectedShieldItemCount)")
                .font(.largeTitle.weight(.semibold))
                .monospacedDigit()
            Text("selected")
                .foregroundStyle(.secondary)
            Text("Use Apple's picker so the lock applies to real apps, categories, and websites.")
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

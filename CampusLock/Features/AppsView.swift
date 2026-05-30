import CampusLockCore
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppsView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Screen Time selection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    selectedSummary
                    nativePickerButton
                    allowedSummary
                }
                .padding(20)
            }
            .background(CampusTheme.background)
            .navigationTitle("Apps")
            #if canImport(FamilyControls)
            .familyActivityPicker(isPresented: $store.isShowingAppPicker, selection: $store.activitySelection)
            #endif
        }
    }

    private var selectedSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(store.selectedShieldItemCount)")
                .font(.largeTitle.weight(.semibold))
            Text("selected")
                .foregroundStyle(.secondary)
            Text("Use Apple's picker so the lock applies to real apps, categories, and websites.")
                .font(.callout)
                .foregroundStyle(.secondary)
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
            }
            Spacer()
        }
        .campusCard(padding: 14)
    }
}

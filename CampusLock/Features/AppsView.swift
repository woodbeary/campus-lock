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
                    Text("Paused during class")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    searchBar
                    categoryRows
                    selectedSummary
                    nativePickerButton
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

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            Text("Search apps or categories")
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var categoryRows: some View {
        VStack(spacing: 12) {
            ForEach(AppCategory.allCases) { category in
                HStack(spacing: 14) {
                    Image(systemName: "square.grid.3x3")
                        .foregroundStyle(category.isSafetyCritical ? .secondary : CampusTheme.accent)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.title)
                            .font(.headline)
                        Text(category.isSafetyCritical ? "Allowed" : "Pause group")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.state.policy.isBlocked(category) },
                        set: { store.setBlocked(category, isBlocked: $0) }
                    ))
                    .labelsHidden()
                    .disabled(category.isSafetyCritical)
                }
                .campusCard(padding: 14)
            }
        }
    }

    private var selectedSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(store.state.policy.blockedCategories.count)")
                .font(.largeTitle.weight(.semibold))
            Text("groups pause in focus")
                .foregroundStyle(.secondary)
            Text("Phone, Messages, and Maps stay available.")
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
            Label("Choose Specific Apps", systemImage: "slider.horizontal.3")
        }
        .buttonStyle(CampusSecondaryButtonStyle())
        .accessibilityIdentifier("apps.chooseSpecific")
    }
}

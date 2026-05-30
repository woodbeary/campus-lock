import CampusLockCore
import MapKit
import SwiftUI

struct ZoneView: View {
    @Environment(CampusLockStore.self) private var store
    @State private var didEnableZone = false

    var body: some View {
        @Bindable var store = store
        CampusScreen {
            CampusScreenHeader(
                title: "Zone",
                subtitle: "Draw the classroom radius around your current location.",
                symbol: "location"
            )
            if let currentLocation = store.state.currentLocation {
                ZoneMapCard(
                    center: currentLocation,
                    radius: store.state.zone.radiusMeters
                )
            } else {
                LocationPendingCard(
                    status: store.locationStatus.label,
                    isLocating: store.isLocating
                )
            }
            radiusCard
        }
        .campusFixedAction {
            bottomAction
        }
        .sensoryFeedback(.selection, trigger: Int(store.state.zone.radiusMeters))
        .sensoryFeedback(.success, trigger: didEnableZone)
        .task {
            if store.state.currentLocation == nil {
                await store.requestLocationRefresh()
            }
        }
    }

    private var bottomAction: some View {
        Button {
            Task {
                if store.state.currentLocation == nil || !store.locationStatus.isUsable {
                    await store.requestLocationRefresh()
                } else {
                    didEnableZone.toggle()
                    store.startFocus()
                    store.selectedTab = .lock
                }
            }
        } label: {
            if store.state.currentLocation == nil || !store.locationStatus.isUsable {
                Label(store.isLocating ? "Locating" : "Use Current Location", systemImage: store.isLocating ? "location.magnifyingglass" : "location.fill")
            } else {
                Label("Enable Zone", systemImage: "location.fill")
            }
        }
        .buttonStyle(CampusPrimaryButtonStyle())
        .disabled(store.isLocating)
        .accessibilityIdentifier("zone.enable")
    }

    private var radiusCard: some View {
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
            .accessibilityIdentifier("zone.radius")
            HStack {
                Text("50 m")
                Spacer()
                Text("500 m")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .campusCard(padding: 12)
    }
}

private struct LocationPendingCard: View {
    var status: String
    var isLocating: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(CampusTheme.accent.opacity(0.14), lineWidth: 10)
                    .frame(width: 116, height: 116)
                Image(systemName: isLocating ? "location.magnifyingglass" : "location.circle")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(CampusTheme.accent)
                    .symbolEffect(.pulse, value: isLocating)
            }

            VStack(spacing: 5) {
                Text(isLocating ? "Finding Current Location" : "Current Location Needed")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(status == "Ready" ? "Keep the iPhone awake while GPS updates the class zone." : "Allow Location so the radius is drawn where you are, not from a demo fallback.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .campusCard()
    }
}

private struct ZoneMapCard: View {
    var center: Coordinate
    var radius: Double
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            MapCircle(center: coordinate, radius: radius)
                .foregroundStyle(CampusTheme.accent.opacity(0.18))
                .stroke(CampusTheme.accent, lineWidth: 2)
            Annotation("Class Zone", coordinate: coordinate) {
                Circle()
                    .fill(CampusTheme.accent)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Circle().stroke(.background, lineWidth: 4)
                    }
            }
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
        }
        .overlay(alignment: .bottom) {
            Text("\(Int(radius)) m")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.background, in: Capsule())
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 198)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(.separator).opacity(0.24), lineWidth: 0.5)
        }
        .onAppear(perform: refreshCamera)
        .onChange(of: center) { _, _ in refreshCamera() }
        .onChange(of: radius) { _, _ in refreshCamera() }
    }

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
    }

    private func refreshCamera() {
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: coordinate,
                distance: max(radius * 4, 450),
                heading: 0,
                pitch: 0
            )
        )
    }
}

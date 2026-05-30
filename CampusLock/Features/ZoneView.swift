import CampusLockCore
import MapKit
import SwiftUI

struct ZoneView: View {
    @Environment(CampusLockStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Current location radius")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ZoneMapCard(center: store.state.zone.center, radius: store.state.zone.radiusMeters)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Radius")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(store.state.zone.radiusMeters)) meters")
                        .font(.title2.weight(.semibold))
                    Slider(
                        value: Binding(
                            get: { store.state.zone.radiusMeters },
                            set: { store.updateRadius($0) }
                        ),
                        in: 50...500,
                        step: 10
                    )
                    .accessibilityIdentifier("zone.radius")
                }
                .campusCard()
                Button("Enable Zone") {
                    store.startFocus()
                    store.selectedTab = .lock
                }
                .buttonStyle(CampusPrimaryButtonStyle())
                Spacer()
            }
            .padding(20)
            .background(CampusTheme.background)
            .navigationTitle("Zone")
        }
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
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .campusGlass(cornerRadius: 28)
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

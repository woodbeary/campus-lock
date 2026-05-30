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
            ZoneMapCard(
                center: store.state.zone.center,
                radius: store.state.zone.radiusMeters
            )
            radiusCard
        }
        .campusFixedAction {
            Button {
                didEnableZone.toggle()
                store.startFocus()
                store.selectedTab = .lock
            } label: {
                Label("Enable Zone", systemImage: "location.fill")
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .accessibilityIdentifier("zone.enable")
        }
        .sensoryFeedback(.selection, trigger: Int(store.state.zone.radiusMeters))
        .sensoryFeedback(.success, trigger: didEnableZone)
    }

    private var radiusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
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
        .frame(height: 268)
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

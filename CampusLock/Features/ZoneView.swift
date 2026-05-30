import CampusLockCore
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
                ZoneMapCard(radius: store.state.zone.radiusMeters)
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
    var radius: Double

    var body: some View {
        ZStack {
            GridBackground()
            Circle()
                .fill(CampusTheme.accent.opacity(0.16))
                .overlay {
                    Circle().stroke(CampusTheme.accent, lineWidth: 3)
                }
                .frame(width: max(140, min(300, radius * 1.35)), height: max(140, min(300, radius * 1.35)))
            Circle()
                .fill(CampusTheme.accent)
                .frame(width: 16, height: 16)
            Text("\(Int(radius)) m")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.background, in: Capsule())
                .offset(y: 128)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .campusGlass(cornerRadius: 28)
    }
}

private struct GridBackground: View {
    var body: some View {
        Canvas { context, size in
            let lineColor = Color(.separator).opacity(0.5)
            for index in stride(from: -size.height, through: size.width, by: 58) {
                var path = Path()
                path.move(to: CGPoint(x: index, y: 0))
                path.addLine(to: CGPoint(x: index + size.height * 0.35, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }
            for index in stride(from: 0, through: size.height * 1.2, by: 58) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: index))
                path.addLine(to: CGPoint(x: size.width, y: index - size.width * 0.18))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }
}

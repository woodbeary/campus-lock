import SwiftUI

enum CampusTheme {
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let elevated = Color(.systemBackground)
    static let accent = Color.blue
    static let success = Color.green
}

struct CampusCard: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CampusTheme.elevated, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

struct CampusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(Color(.systemBackground))
            .background(Color.primary.opacity(configuration.isPressed ? 0.82 : 1), in: Capsule())
            .contentShape(Capsule())
    }
}

struct CampusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.primary)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            .overlay {
                Capsule().stroke(Color(.separator), lineWidth: 0.5)
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Capsule())
    }
}

extension View {
    func campusCard(padding: CGFloat = 18) -> some View {
        modifier(CampusCard(padding: padding))
    }

    @ViewBuilder
    func campusGlass(cornerRadius: CGFloat = 24, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self.background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

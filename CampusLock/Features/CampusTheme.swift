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

struct CampusScreenHeader: View {
    var title: String
    var subtitle: String
    var symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 40, height: 40)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct CampusBottomBar<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(.regularMaterial)
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

    func campusLoadIn() -> some View {
        modifier(CampusLoadInModifier())
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

private struct CampusLoadInModifier: ViewModifier {
    @State private var didAppear = false

    func body(content: Content) -> some View {
        content
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 8)
            .animation(.snappy(duration: 0.32), value: didAppear)
            .onAppear {
                didAppear = true
            }
    }
}

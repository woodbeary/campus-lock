import SwiftUI

enum CampusTheme {
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let elevated = Color(.secondarySystemGroupedBackground)
    static let accent = Color.blue
    static let success = Color.green
    static let screenHorizontalPadding: CGFloat = 20
    static let screenTopPadding: CGFloat = 14
    static let screenSpacing: CGFloat = 14

    static func scrollBottomPadding(hasAction: Bool = true) -> CGFloat {
        hasAction ? 18 : 24
    }
}

struct CampusCard: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CampusTheme.elevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
            }
    }
}

struct CampusScreenHeader: View {
    var title: String
    var subtitle: String
    var symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 36, height: 36)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
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
            .frame(maxWidth: .infinity)
            .padding(.horizontal, CampusTheme.screenHorizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(.regularMaterial)
    }
}

struct CampusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
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
            .frame(height: 52)
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

    func campusFixedAction<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            CampusBottomBar {
                content()
            }
        }
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

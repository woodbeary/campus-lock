import SwiftUI

enum CampusTheme {
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let elevated = Color(.secondarySystemGroupedBackground)
    static let accent = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let screenHorizontalPadding: CGFloat = 20
    static let screenTopPadding: CGFloat = 18
    static let screenSpacing: CGFloat = 18
    static let contentMaxWidth: CGFloat = 430

    static func scrollBottomPadding(hasAction: Bool = true) -> CGFloat {
        hasAction ? 18 : 28
    }
}

struct CampusScreen<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let background: Color
    private let content: Content

    init(
        alignment: HorizontalAlignment = .leading,
        background: Color = CampusTheme.background,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.background = background
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: alignment, spacing: CampusTheme.screenSpacing) {
                content
            }
            .frame(maxWidth: CampusTheme.contentMaxWidth, alignment: Alignment(horizontal: alignment, vertical: .top))
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
            .padding(.horizontal, CampusTheme.screenHorizontalPadding)
            .padding(.top, CampusTheme.screenTopPadding)
            .padding(.bottom, CampusTheme.scrollBottomPadding())
            .campusLoadIn()
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .background(background)
    }
}

struct CampusCard: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CampusTheme.elevated.opacity(0.74), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .campusGlass(cornerRadius: 24)
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
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CampusTheme.accent)
                .frame(width: 34, height: 34)
                .background(CampusTheme.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct CampusBottomBar<Content: View>: View {
    private let background: Color
    private let content: Content

    init(background: Color = CampusTheme.background, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: CampusTheme.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, CampusTheme.screenHorizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background {
                background.ignoresSafeArea()
            }
    }
}

struct CampusGlassGroup<Content: View>: View {
    var spacing: CGFloat? = nil
    private let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

struct CampusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.primary)
                .glassEffect(.regular.tint(CampusTheme.accent.opacity(configuration.isPressed ? 0.18 : 0.26)).interactive(), in: Capsule())
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .contentShape(Capsule())
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
        } else {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(Color(.systemBackground))
                .background(Color.primary.opacity(configuration.isPressed ? 0.82 : 1), in: Capsule())
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .contentShape(Capsule())
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
        }
    }
}

struct CampusSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.primary)
                .glassEffect(.regular.interactive(), in: Capsule())
                .opacity(configuration.isPressed ? 0.75 : 1)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .contentShape(Capsule())
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
        } else {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.primary)
                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                .overlay {
                    Capsule().stroke(Color(.separator), lineWidth: 0.5)
                }
                .opacity(configuration.isPressed ? 0.75 : 1)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .contentShape(Capsule())
                .animation(.snappy(duration: 0.16), value: configuration.isPressed)
        }
    }
}

extension View {
    func campusCard(padding: CGFloat = 18) -> some View {
        modifier(CampusCard(padding: padding))
    }

    func campusLoadIn() -> some View {
        modifier(CampusLoadInModifier())
    }

    func campusFixedAction<Content: View>(
        background: Color = CampusTheme.background,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            CampusBottomBar(background: background) {
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

    @ViewBuilder
    func campusPrimaryAction() -> some View {
        if #available(iOS 26.0, *) {
            self
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .buttonBorderShape(.capsule)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        } else {
            self.buttonStyle(CampusPrimaryButtonStyle())
        }
    }

    @ViewBuilder
    func campusSecondaryAction() -> some View {
        if #available(iOS 26.0, *) {
            self
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .buttonBorderShape(.capsule)
                .buttonStyle(.glass)
                .controlSize(.large)
        } else {
            self.buttonStyle(CampusSecondaryButtonStyle())
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

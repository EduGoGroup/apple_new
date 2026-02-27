import SwiftUI

// MARK: - Skeleton Shape

/// Formas disponibles para skeleton loaders
public enum EduSkeletonShape: Sendable {
    case rectangle
    case roundedRectangle(CGFloat)
    case circle
    case capsule
}

// MARK: - Skeleton Loader

/// Skeleton loader con efecto shimmer optimizado
///
/// Usa animaciones energy-efficient y soporta accessibility.
@MainActor
public struct EduSkeletonLoader: View {
    private let shape: EduSkeletonShape
    @State private var opacity: Double = 0.3

    // Constantes para animación
    private let minOpacity: Double = 0.3
    private let maxOpacity: Double = 0.6
    private let animationDuration: Double = 0.8

    public init(shape: EduSkeletonShape = .roundedRectangle(DesignTokens.CornerRadius.medium)) {
        self.shape = shape
    }

    public var body: some View {
        Group {
            switch shape {
            case .rectangle:
                Rectangle()
            case .roundedRectangle(let radius):
                RoundedRectangle(cornerRadius: radius)
            case .circle:
                Circle()
            case .capsule:
                Capsule()
            }
        }
        .foregroundStyle(Color(white: 0.85))
        .opacity(opacity)
        .accessibilityLabel("Loading content")
        .accessibilityAddTraits(.updatesFrequently)
        .accessibleIdentifier(.loading(module: "ui", screen: "skeleton"))
        // MARK: - Keyboard Navigation
        .skipInTabOrder()
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                opacity = maxOpacity
            }
            // Announce loading started (low priority to not interrupt)
            AccessibilityAnnouncements.announce("Loading content", priority: .low)
        }
    }
}

// MARK: - Skeleton Text

/// Skeleton para texto
@MainActor
public struct EduSkeletonText: View {
    private let lines: Int
    private let spacing: CGFloat

    public init(lines: Int = 1, spacing: CGFloat = DesignTokens.Spacing.small) {
        self.lines = lines
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 12)
                    .frame(width: widthForLine(index))
            }
        }
    }

    private func widthForLine(_ index: Int) -> CGFloat? {
        if index == lines - 1 && lines > 1 {
            return nil // Last line takes 70% width
        }
        return nil
    }
}

// MARK: - Skeleton Image

/// Skeleton para imágenes
@MainActor
public struct EduSkeletonImage: View {
    private let aspectRatio: CGFloat?
    private let shape: EduSkeletonShape

    public init(aspectRatio: CGFloat? = 1.0, shape: EduSkeletonShape = .roundedRectangle(DesignTokens.CornerRadius.xl)) {
        self.aspectRatio = aspectRatio
        self.shape = shape
    }

    public var body: some View {
        EduSkeletonLoader(shape: shape)
            .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// MARK: - Skeleton Card

/// Skeleton para cards
@MainActor
public struct EduSkeletonCard: View {
    private let showImage: Bool
    private let lines: Int

    public init(showImage: Bool = true, lines: Int = 3) {
        self.showImage = showImage
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            if showImage {
                EduSkeletonImage(aspectRatio: 16/9)
                    .frame(height: 180)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                // Title
                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Description lines
                EduSkeletonText(lines: lines, spacing: 6)
            }
            .padding(showImage ? DesignTokens.Spacing.medium : 0)
        }
        .padding(DesignTokens.Spacing.large)
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }
}

// MARK: - Skeleton List

/// Skeleton para listas
@MainActor
public struct EduSkeletonList: View {
    private let count: Int

    public init(count: Int = 5) {
        self.count = count
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            ForEach(0..<count, id: \.self) { _ in
                EduSkeletonListRow()
            }
        }
    }
}

// MARK: - Skeleton List Row

/// Skeleton para row de lista
@MainActor
public struct EduSkeletonListRow: View {
    public init() {}

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            EduSkeletonLoader(shape: .circle)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 14)
                    .frame(maxWidth: 200)

                EduSkeletonLoader(shape: .capsule)
                    .frame(height: 10)
                    .frame(maxWidth: 150)
            }

            Spacer()
        }
        .padding()
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }
}

// MARK: - Shimmer Effect

/// Efecto shimmer para skeleton loaders con animación energy-efficient
@MainActor
public struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    // Constantes para shimmer effect
    private let shimmerDuration: Double = 1.5
    private let shimmerDistance: CGFloat = 400
    private let shimmerOpacity: Double = 0.3

    public func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(shimmerOpacity),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: shimmerDuration).repeatForever(autoreverses: false)) {
                    phase = shimmerDistance
                }
            }
    }
}

extension View {
    /// Aplica efecto shimmer a la vista
    public func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Group

/// Grupo de skeletons con shimmer
@MainActor
public struct EduSkeletonGroup<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .shimmer()
    }
}

// MARK: - Previews

#Preview("Formas básicas") {
    VStack(spacing: 24) {
        EduSkeletonLoader(shape: .rectangle)
            .frame(height: 40)
        EduSkeletonLoader(shape: .roundedRectangle(12))
            .frame(height: 40)
        EduSkeletonLoader(shape: .capsule)
            .frame(height: 40)
        EduSkeletonLoader(shape: .circle)
            .frame(width: 60, height: 60)
    }
    .padding()
}

#Preview("Skeleton Text") {
    VStack(alignment: .leading, spacing: 24) {
        EduSkeletonText(lines: 1)
        EduSkeletonText(lines: 3)
        EduSkeletonText(lines: 5, spacing: 10)
    }
    .padding()
}

#Preview("Skeleton Image") {
    VStack(spacing: 24) {
        EduSkeletonImage(aspectRatio: 16/9)
            .frame(height: 180)
        EduSkeletonImage(aspectRatio: 1.0, shape: .circle)
            .frame(width: 100, height: 100)
    }
    .padding()
}

#Preview("Skeleton Card") {
    VStack(spacing: 16) {
        EduSkeletonCard()
        EduSkeletonCard(showImage: false, lines: 2)
    }
    .padding()
}

#Preview("Skeleton List") {
    EduSkeletonList(count: 4)
        .padding()
}

#Preview("Skeleton List Row") {
    VStack(spacing: 8) {
        EduSkeletonListRow()
        EduSkeletonListRow()
        EduSkeletonListRow()
    }
    .padding()
}

#Preview("Con Shimmer Effect") {
    EduSkeletonGroup {
        VStack(spacing: 16) {
            EduSkeletonListRow()
            EduSkeletonListRow()
            EduSkeletonListRow()
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        EduSkeletonCard(showImage: false, lines: 2)
        EduSkeletonListRow()
    }
    .padding()
    .preferredColorScheme(.dark)
}

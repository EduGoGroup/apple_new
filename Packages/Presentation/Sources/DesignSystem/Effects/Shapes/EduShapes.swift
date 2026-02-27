// EduShapes.swift
// Effects
//
// Custom shapes for liquid glass effects - iOS 26+ and macOS 26+

import SwiftUI

// MARK: - Liquid Rounded Rectangle

/// A rounded rectangle shape with liquid-like smooth corners
@available(iOS 26.0, macOS 26.0, *)
public struct EduLiquidRoundedRectangle: Shape, Sendable {
    public var cornerRadius: CGFloat
    public var smoothness: CGFloat

    public init(cornerRadius: CGFloat = 16, smoothness: CGFloat = 0.6) {
        self.cornerRadius = cornerRadius
        self.smoothness = min(max(smoothness, 0), 1)
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(cornerRadius, smoothness) }
        set {
            cornerRadius = newValue.first
            smoothness = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
        let smoothFactor = 1 + (smoothness * 0.552284749831)

        var path = Path()

        // Start from top-left after the corner
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))

        // Top-right corner with smooth curve
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control1: CGPoint(x: rect.maxX - radius + radius * smoothFactor * 0.5, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + radius - radius * smoothFactor * 0.5)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))

        // Bottom-right corner
        path.addCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - radius + radius * smoothFactor * 0.5),
            control2: CGPoint(x: rect.maxX - radius + radius * smoothFactor * 0.5, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))

        // Bottom-left corner
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control1: CGPoint(x: rect.minX + radius - radius * smoothFactor * 0.5, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - radius + radius * smoothFactor * 0.5)
        )

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))

        // Top-left corner
        path.addCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + radius - radius * smoothFactor * 0.5),
            control2: CGPoint(x: rect.minX + radius - radius * smoothFactor * 0.5, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Morphable Shape

/// Enum representing shapes that can morph between each other
@available(iOS 26.0, macOS 26.0, *)
public enum EduMorphableShape: Sendable, Equatable {
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case circle
    case capsule
    case blob(seed: Int)

    public var cornerFactor: CGFloat {
        switch self {
        case .rectangle: return 0
        case .roundedRectangle(let cornerRadius): return cornerRadius
        case .circle: return .infinity
        case .capsule: return .infinity
        case .blob: return 0.5
        }
    }
}

// MARK: - Shape Morphing Modifier

/// Modifier that enables smooth morphing between shapes
@available(iOS 26.0, macOS 26.0, *)
public struct EduShapeMorphingModifier: ViewModifier {
    public let shape: EduMorphableShape
    public let animation: Animation

    public init(shape: EduMorphableShape, animation: Animation = .spring()) {
        self.shape = shape
        self.animation = animation
    }

    public func body(content: Content) -> some View {
        content
            .clipShape(AnyShape(shapeView))
            .animation(animation, value: shape.cornerFactor)
    }

    private var shapeView: AnyShape {
        switch shape {
        case .rectangle:
            AnyShape(Rectangle())
        case .roundedRectangle(let cornerRadius):
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .circle:
            AnyShape(Circle())
        case .capsule:
            AnyShape(Capsule())
        case .blob(let seed):
            AnyShape(EduBlobShape(seed: seed))
        }
    }
}

// MARK: - Blob Shape

/// An organic blob-like shape with controllable randomness
@available(iOS 26.0, macOS 26.0, *)
public struct EduBlobShape: Shape, Sendable {
    public var seed: Int
    public var complexity: Int

    public init(seed: Int = 0, complexity: Int = 6) {
        self.seed = seed
        self.complexity = max(3, complexity)
    }

    public var animatableData: Double {
        get { Double(seed) }
        set { seed = Int(newValue) }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2 * 0.8

        var generator = SeededRandomGenerator(seed: UInt64(abs(seed)))

        var points: [CGPoint] = []
        for i in 0..<complexity {
            let angle = (Double(i) / Double(complexity)) * 2 * .pi
            let radiusVariation = 0.8 + generator.nextDouble() * 0.4
            let radius = baseRadius * radiusVariation

            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            points.append(CGPoint(x: x, y: y))
        }

        guard !points.isEmpty else { return path }

        path.move(to: points[0])

        for i in 0..<points.count {
            let current = points[i]
            let next = points[(i + 1) % points.count]
            let control1 = CGPoint(
                x: current.x + (next.x - current.x) * 0.5,
                y: current.y
            )
            let control2 = CGPoint(
                x: current.x + (next.x - current.x) * 0.5,
                y: next.y
            )
            path.addCurve(to: next, control1: control1, control2: control2)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Seeded Random Generator

/// A simple seeded random number generator for consistent blob shapes
@available(iOS 26.0, macOS 26.0, *)
private struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }

    mutating func nextDouble() -> Double {
        Double(next() % 1000) / 1000.0
    }
}

// MARK: - Squircle Shape

/// A superellipse (squircle) shape for iOS-like rounded rectangles
@available(iOS 26.0, macOS 26.0, *)
public struct EduSquircleShape: Shape, Sendable {
    public var cornerRadius: CGFloat
    public var exponent: CGFloat

    public init(cornerRadius: CGFloat = 16, exponent: CGFloat = 4) {
        self.cornerRadius = cornerRadius
        self.exponent = max(2, exponent)
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(cornerRadius, exponent) }
        set {
            cornerRadius = newValue.first
            exponent = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
        return Path(
            roundedRect: rect,
            cornerRadius: radius,
            style: .continuous
        )
    }
}

// MARK: - View Extensions

@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Clips the view to a liquid rounded rectangle
    func eduLiquidClip(
        cornerRadius: CGFloat = 16,
        smoothness: CGFloat = 0.6
    ) -> some View {
        clipShape(EduLiquidRoundedRectangle(
            cornerRadius: cornerRadius,
            smoothness: smoothness
        ))
    }

    /// Applies morphable shape with animation
    func eduMorphShape(
        _ shape: EduMorphableShape,
        animation: Animation = .spring()
    ) -> some View {
        modifier(EduShapeMorphingModifier(shape: shape, animation: animation))
    }

    /// Clips the view to a squircle shape
    func eduSquircle(
        cornerRadius: CGFloat = 16,
        exponent: CGFloat = 4
    ) -> some View {
        clipShape(EduSquircleShape(
            cornerRadius: cornerRadius,
            exponent: exponent
        ))
    }
}

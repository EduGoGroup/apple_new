import SwiftUI

// MARK: - Progress Circle

/// Indicador de progreso circular con accessibility y performance optimizado
@MainActor
public struct EduProgressCircle: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let tint: Color
    private let showPercentage: Bool

    // Constantes
    private let startAngle: Double = -90

    // Progreso normalizado y cacheado
    @State private var normalizedProgress: Double

    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        tint: Color = .accentColor,
        showPercentage: Bool = false
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.tint = tint
        self.showPercentage = showPercentage
        // Inicializar progreso normalizado
        self._normalizedProgress = State(initialValue: min(max(progress, 0), 1))
    }

    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(white: 0.9), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: normalizedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(startAngle))
                .animation(.easeInOut, value: normalizedProgress)

            // Percentage label
            if showPercentage {
                Text("\(Int(normalizedProgress * 100))%")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Circular progress")
        .accessibilityValue("\(Int(normalizedProgress * 100)) percent")
        .accessibilityAddTraits(.updatesFrequently)
        .accessibleIdentifier(.progress(module: "ui", screen: "loading", context: "circular"))
        .onChange(of: progress) { _, newValue in
            let oldNormalized = normalizedProgress
            normalizedProgress = min(max(newValue, 0), 1)

            // Announce only at milestones (25%, 50%, 75%, 100%)
            let oldPercentage = Int(oldNormalized * 100)
            let newPercentage = Int(normalizedProgress * 100)
            if oldPercentage != newPercentage {
                AccessibilityAnnouncements.announceProgressMilestone(normalizedProgress)
            }
        }
    }
}

// MARK: - Indeterminate Circle

/// Círculo de progreso indeterminado con animación
@MainActor
public struct EduIndeterminateCircle: View {
    @State private var isAnimating = false

    private let lineWidth: CGFloat
    private let tint: Color

    public init(lineWidth: CGFloat = 8, tint: Color = .accentColor) {
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Circular Progress with Icon

/// Progreso circular con icono central
@MainActor
public struct EduCircularProgressWithIcon: View {
    private let progress: Double
    private let icon: String
    private let lineWidth: CGFloat
    private let tint: Color

    public init(
        progress: Double,
        icon: String,
        lineWidth: CGFloat = 8,
        tint: Color = .accentColor
    ) {
        self.progress = progress
        self.icon = icon
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            EduProgressCircle(progress: progress, lineWidth: lineWidth, tint: tint)

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Multi-Ring Progress

/// Progreso circular con múltiples anillos
@MainActor
public struct EduMultiRingProgress: View {
    private let rings: [RingData]

    public struct RingData: Identifiable, Sendable {
        public let id = UUID()
        public let progress: Double
        public let color: Color

        public init(progress: Double, color: Color) {
            self.progress = progress
            self.color = color
        }
    }

    public init(rings: [RingData]) {
        self.rings = rings
    }

    public var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                Circle()
                    .trim(from: 0, to: min(max(ring.progress, 0), 1))
                    .stroke(ring.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(CGFloat(index) * 12)
                    .animation(.easeInOut, value: ring.progress)
            }
        }
    }
}

// MARK: - Gauge Style Progress

/// Progreso estilo gauge (semi-círculo)
@MainActor
public struct EduGaugeProgress: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let tint: Color
    private let showValue: Bool

    public init(
        progress: Double,
        lineWidth: CGFloat = 12,
        tint: Color = .accentColor,
        showValue: Bool = true
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.tint = tint
        self.showValue = showValue
    }

    public var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color(white: 0.9), lineWidth: lineWidth)
                .rotationEffect(.degrees(135))

            // Progress arc
            Circle()
                .trim(from: 0, to: 0.75 * min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
                .animation(.easeInOut, value: progress)

            // Value
            if showValue {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("\(Int(progress * 100))")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .offset(y: 20)
            }
        }
    }
}

// MARK: - Previews

#Preview("Progress Circle básico") {
    VStack(spacing: 32) {
        EduProgressCircle(progress: 0.25)
            .frame(width: 80, height: 80)
        EduProgressCircle(progress: 0.50)
            .frame(width: 80, height: 80)
        EduProgressCircle(progress: 0.75)
            .frame(width: 80, height: 80)
    }
    .padding()
}

#Preview("Con porcentaje") {
    EduProgressCircle(progress: 0.68, showPercentage: true)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Indeterminado") {
    EduIndeterminateCircle()
        .frame(width: 80, height: 80)
        .padding()
}

#Preview("Con icono") {
    VStack(spacing: 32) {
        EduCircularProgressWithIcon(progress: 0.75, icon: "arrow.down")
            .frame(width: 80, height: 80)
        EduCircularProgressWithIcon(progress: 1.0, icon: "checkmark")
            .frame(width: 80, height: 80)
    }
    .padding()
}

#Preview("Multi-Ring") {
    EduMultiRingProgress(rings: [
        .init(progress: 0.8, color: .red),
        .init(progress: 0.6, color: .green),
        .init(progress: 0.4, color: .blue)
    ])
    .frame(width: 120, height: 120)
    .padding()
}

#Preview("Gauge Progress") {
    VStack(spacing: 32) {
        EduGaugeProgress(progress: 0.35)
            .frame(width: 150, height: 150)
        EduGaugeProgress(progress: 0.75, tint: .green)
            .frame(width: 150, height: 150)
    }
    .padding()
}

#Preview("Colores personalizados") {
    HStack(spacing: 24) {
        EduProgressCircle(progress: 0.7, tint: .green)
            .frame(width: 60, height: 60)
        EduProgressCircle(progress: 0.7, tint: .orange)
            .frame(width: 60, height: 60)
        EduProgressCircle(progress: 0.7, tint: .purple)
            .frame(width: 60, height: 60)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 32) {
        EduProgressCircle(progress: 0.65, showPercentage: true)
            .frame(width: 100, height: 100)
        EduGaugeProgress(progress: 0.5)
            .frame(width: 120, height: 120)
    }
    .padding()
    .preferredColorScheme(.dark)
}

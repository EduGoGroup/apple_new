import SwiftUI
import DesignSystemSDK

// MARK: - Progress Bar Mode

/// Modo del progress bar
public enum EduProgressBarMode: Sendable {
    case determinate(Double) // 0.0 a 1.0
    case indeterminate
}

// MARK: - Progress Bar Style

/// Estilos para el progress bar
public enum EduProgressBarStyle: Sendable {
    case linear
    case rounded
    case thin
}

// MARK: - Progress Bar

/// Barra de progreso lineal con modo determinado e indeterminado
///
/// Incluye validación de progreso y soporte de accessibility.
public struct EduProgressBar: View {
    private let mode: EduProgressBarMode
    private let style: EduProgressBarStyle
    private let tint: Color
    private let backgroundColor: Color

    // Constantes para animación
    private let animationDuration: Double = 0.3

    public init(
        mode: EduProgressBarMode,
        style: EduProgressBarStyle = .rounded,
        tint: Color = .accentColor,
        backgroundColor: Color = Color(white: 0.9)
    ) {
        self.mode = mode
        self.style = style
        self.tint = tint
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        switch mode {
        case .determinate(let progress):
            determinateBar(progress: progress)
        case .indeterminate:
            indeterminateBar
        }
    }

    @ViewBuilder
    private func determinateBar(progress: Double) -> some View {
        let clampedProgress = min(max(progress, 0), 1)

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Group {
                    switch style {
                    case .linear:
                        Rectangle()
                    case .rounded:
                        RoundedRectangle(cornerRadius: heightForStyle / 2)
                    case .thin:
                        Capsule()
                    }
                }
                .foregroundStyle(backgroundColor)

                // Progress
                Group {
                    switch style {
                    case .linear:
                        Rectangle()
                    case .rounded:
                        RoundedRectangle(cornerRadius: heightForStyle / 2)
                    case .thin:
                        Capsule()
                    }
                }
                .foregroundStyle(tint)
                .frame(width: geometry.size.width * clampedProgress)
                .animation(.easeInOut(duration: animationDuration), value: clampedProgress)
            }
        }
        .frame(height: heightForStyle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress bar")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
        .accessibilityAddTraits(.updatesFrequently)
        .accessibleIdentifier(.progress(module: "ui", screen: "loading", context: "linear"))
        // MARK: - Keyboard Navigation
        .skipInTabOrder()
        .onChange(of: clampedProgress) { _, newValue in
            // Announce only at milestones (25%, 50%, 75%, 100%)
            AccessibilityAnnouncements.announceProgressMilestone(newValue)
        }
    }

    @ViewBuilder
    private var indeterminateBar: some View {
        ProgressView()
            .progressViewStyle(.linear)
            .tint(tint)
            .frame(height: heightForStyle)
    }

    private var heightForStyle: CGFloat {
        switch style {
        case .linear: return 4
        case .rounded: return 8
        case .thin: return 2
        }
    }
}

// MARK: - Progress Bar with Label

/// Progress bar con etiqueta de porcentaje
public struct EduLabeledProgressBar: View {
    private let progress: Double
    private let showPercentage: Bool
    private let label: String?
    private let style: EduProgressBarStyle
    private let tint: Color

    public init(
        progress: Double,
        showPercentage: Bool = true,
        label: String? = nil,
        style: EduProgressBarStyle = .rounded,
        tint: Color = .accentColor
    ) {
        self.progress = progress
        self.showPercentage = showPercentage
        self.label = label
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                if let label {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            EduProgressBar(
                mode: .determinate(progress),
                style: style,
                tint: tint
            )
        }
    }
}

// MARK: - Segmented Progress Bar

/// Barra de progreso segmentada para steps
public struct EduSegmentedProgressBar: View {
    private let totalSteps: Int
    private let currentStep: Int
    private let tint: Color

    public init(totalSteps: Int, currentStep: Int, tint: Color = .accentColor) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < currentStep ? tint : Color(white: 0.9))
                    .frame(height: DesignTokens.Spacing.xs)
            }
        }
    }
}

// MARK: - Previews

#Preview("Progress Bar - Determinado") {
    VStack(spacing: 24) {
        EduProgressBar(mode: .determinate(0.25))
        EduProgressBar(mode: .determinate(0.50))
        EduProgressBar(mode: .determinate(0.75))
        EduProgressBar(mode: .determinate(1.0))
    }
    .padding()
}

#Preview("Progress Bar - Estilos") {
    VStack(spacing: 24) {
        EduProgressBar(mode: .determinate(0.6), style: .linear)
        EduProgressBar(mode: .determinate(0.6), style: .rounded)
        EduProgressBar(mode: .determinate(0.6), style: .thin)
    }
    .padding()
}

#Preview("Progress Bar - Indeterminado") {
    EduProgressBar(mode: .indeterminate)
        .padding()
}

#Preview("Progress Bar con etiqueta") {
    VStack(spacing: 24) {
        EduLabeledProgressBar(progress: 0.35, label: "Descargando...")
        EduLabeledProgressBar(progress: 0.75, label: "Subiendo archivo")
        EduLabeledProgressBar(progress: 1.0, label: "Completado")
    }
    .padding()
}

#Preview("Progress Bar segmentado") {
    VStack(spacing: 24) {
        EduSegmentedProgressBar(totalSteps: 5, currentStep: 1)
        EduSegmentedProgressBar(totalSteps: 5, currentStep: 3)
        EduSegmentedProgressBar(totalSteps: 5, currentStep: 5)
    }
    .padding()
}

#Preview("Colores personalizados") {
    VStack(spacing: 24) {
        EduProgressBar(mode: .determinate(0.6), tint: .green)
        EduProgressBar(mode: .determinate(0.6), tint: .orange)
        EduProgressBar(mode: .determinate(0.6), tint: .purple)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 24) {
        EduProgressBar(mode: .determinate(0.5))
        EduLabeledProgressBar(progress: 0.75, label: "Progreso")
        EduSegmentedProgressBar(totalSteps: 4, currentStep: 2)
    }
    .padding()
    .preferredColorScheme(.dark)
}

import SwiftUI

/// Sheet para seleccionar la modalidad de creacion de evaluacion.
///
/// Presenta dos opciones:
/// - **Manual**: permite crear evaluacion manualmente (activo)
/// - **Con IA**: genera evaluacion automaticamente (proximamente)
///
/// ## Ejemplo de uso
/// ```swift
/// .sheet(isPresented: $showModalitySheet) {
///     ModalitySelectorSheet(onManualSelected: {
///         showModalitySheet = false
///         navigateToForm(sourceType: "manual")
///     })
/// }
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct ModalitySelectorSheet: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    private let onManualSelected: () -> Void

    // MARK: - Initialization

    /// Crea el sheet de seleccion de modalidad.
    ///
    /// - Parameter onManualSelected: Callback cuando se selecciona "Manual".
    public init(onManualSelected: @escaping () -> Void) {
        self.onManualSelected = onManualSelected
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.xl) {
                headerSection

                VStack(spacing: DesignTokens.Spacing.large) {
                    manualCard
                    aiCard
                }
                .padding(.horizontal, DesignTokens.Spacing.large)

                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.xl)
            .navigationTitle("Nueva evaluacion")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "doc.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            Text("Selecciona como crear tu evaluacion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
    }

    private var manualCard: some View {
        Button {
            onManualSelected()
        } label: {
            HStack(spacing: DesignTokens.Spacing.medium) {
                Image(systemName: "hand.draw")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Manual")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Crea preguntas una por una con control total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(DesignTokens.Spacing.large)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }

    private var aiCard: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.quaternary)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(spacing: DesignTokens.Spacing.small) {
                    Text("Con IA")
                        .font(.headline)
                        .foregroundStyle(.tertiary)

                    Text("Proximamente")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, DesignTokens.Spacing.small)
                        .padding(.vertical, 2)
                        .background(.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }

                Text("Genera preguntas automaticamente desde tus materiales")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.large)
        .background(.regularMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

import SwiftUI

/// Helpers para migrar código legacy a usar el nuevo sistema de theming.
///
/// Este tipo proporciona utilities para facilitar la transición de estilos
/// hardcoded a estilos theme-aware.
///
/// ## Uso
/// ```swift
/// // Antes (legacy):
/// Text("Error").foregroundColor(.red)
///
/// // Después (themed):
/// Text("Error").foregroundColor(Color.theme.error)
/// ```
public enum ThemeMigration {

    // MARK: - Color Migration

    /// Convierte un color legacy a su equivalente semantic color.
    ///
    /// - Parameter legacyColor: Color hardcoded a migrar
    /// - Returns: Semantic color equivalente o nil si no hay mapeo directo
    @MainActor
    public static func migrateColor(_ legacyColor: Color) -> Color? {
        // Esta función ayuda en la migración pero no es exhaustiva
        // Los desarrolladores deben usar Color.theme.* directamente

        // Mapeos comunes:
        if legacyColor == .red {
            return Color.theme.error
        } else if legacyColor == .green {
            return Color.theme.success
        } else if legacyColor == .blue {
            return Color.theme.interactive
        } else if legacyColor == .yellow {
            return Color.theme.warning
        } else if legacyColor == .secondary {
            return Color.theme.textSecondary
        } else if legacyColor == .primary {
            return Color.theme.textPrimary
        }

        return nil
    }

    // MARK: - Style Migration

    /// Guía de migración para ValidationFieldStyle
    public struct ValidationFieldStyleMigration {
        /// Migrar de .default a .themed
        public static let guide = """
        Antes:
        .validated(state, style: .default)

        Después:
        .validated(state, style: .themed)

        Cambios:
        - errorColor: .red → Color.theme.error
        - validColor: .green → Color.theme.success
        """
    }

    /// Guía de migración para FormErrorBannerStyle
    public struct FormErrorBannerStyleMigration {
        /// Migrar de .default a .themed
        public static let guide = """
        Antes:
        .formErrorBanner(state, style: .default)

        Después:
        .formErrorBanner(state, style: .themed)

        Cambios:
        - backgroundColor: .red → Color.theme.error
        - textColor: .white → Color.theme.textOnError
        """
    }

    /// Guía de migración para ProgressBarStyle
    public struct ProgressBarStyleMigration {
        /// Migrar de .default a .themed
        public static let guide = """
        Antes:
        .progressBar(progress, style: .default)

        Después:
        .progressBar(progress, style: .themed)

        Cambios:
        - labelColor: .secondary → Color.theme.textSecondary
        - progressColor: nil → Color.theme.interactive
        """
    }

    /// Guía de migración para LoadingOverlayStyle
    public struct LoadingOverlayStyleMigration {
        /// Migrar de .default a .themed
        public static let guide = """
        Antes:
        .loadingOverlay(isLoading, style: .default)

        Después:
        .loadingOverlay(isLoading, style: .themed)

        Cambios:
        - spinnerColor: nil → Color.theme.interactive
        - messageColor: .secondary → Color.theme.textSecondary
        - shadowColor: .black.opacity(0.1) → Color.theme.shadowMedium
        """
    }

    // MARK: - Deprecation Warnings

    #if DEBUG
    /// Imprime advertencia de deprecación para estilos legacy
    public static func warnLegacyStyle(_ styleName: String) {
        print("⚠️ [ThemeMigration] Warning: Using legacy style '\(styleName)'. Consider migrating to .themed variant for better theming support.")
    }
    #endif
}

// MARK: - View Extensions para Migración

extension View {

    /// Helper para migrar fácilmente a estilos themed.
    ///
    /// Este modifier sugiere usar el estilo themed y facilita la transición.
    ///
    /// - Returns: Vista sin cambios (solo documentación)
    @available(*, deprecated, message: "Use .themed style variants for better theming support")
    public func migrateToThemedStyles() -> some View {
        self
    }
}

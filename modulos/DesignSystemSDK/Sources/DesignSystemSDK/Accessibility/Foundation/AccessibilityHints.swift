import SwiftUI

/// Hints de accesibilidad que proporcionan información adicional sobre el comportamiento de elementos UI.
///
/// Los hints son descripciones opcionales que:
/// - Explican QUÉ pasará cuando el usuario interactúe con el elemento
/// - NO duplican información del label (el label dice QUÉ es, el hint dice QUÉ hace)
/// - Son concisos y directos
/// - Solo se agregan cuando aportan valor real
///
/// ## Mejores Prácticas
/// - ✅ USAR hints cuando el comportamiento no es obvio
/// - ❌ NO usar hints redundantes (ej: "Button" en un botón obvio)
/// - ✅ Describir el resultado de la acción
/// - ❌ NO describir cómo activar el elemento (VoiceOver ya lo hace)
///
/// ## Ejemplo
/// ```swift
/// Button("Delete") { }
///     .accessibleLabel("Delete photo")
///     .accessibleHint("Permanently removes this photo from your library")
/// ```
public struct AccessibilityHint: Sendable {
    private let text: String

    private init(_ text: String) {
        self.text = text
    }

    /// Texto del hint
    public var value: String {
        text
    }

    // MARK: - Static Constructors

    /// Crea un hint simple de texto
    public static func text(_ text: String) -> AccessibilityHint {
        AccessibilityHint(text)
    }

    /// Crea un hint localizado
    public static func localized(_ key: String, comment: String = "") -> AccessibilityHint {
        AccessibilityHint(NSLocalizedString(key, comment: comment))
    }

    /// Crea un hint que describe una acción de navegación
    ///
    /// Ejemplo: "Opens the settings screen"
    public static func opensScreen(_ screenName: String) -> AccessibilityHint {
        AccessibilityHint("Opens the \(screenName) screen")
    }

    /// Crea un hint que describe una acción de cierre/dismissal
    public static func dismisses(_ what: String = "this screen") -> AccessibilityHint {
        AccessibilityHint("Dismisses \(what)")
    }

    /// Crea un hint que describe una acción de guardado
    public static func saves(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Saves \(what)")
    }

    /// Crea un hint que describe una acción de eliminación
    ///
    /// Ejemplo: "Permanently deletes this item"
    public static func deletes(_ what: String, permanent: Bool = false) -> AccessibilityHint {
        let prefix = permanent ? "Permanently deletes" : "Deletes"
        return AccessibilityHint("\(prefix) \(what)")
    }

    /// Crea un hint que describe una acción de edición
    public static func edits(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Allows you to edit \(what)")
    }

    /// Crea un hint que describe una acción de compartir
    public static func shares(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Opens share options for \(what)")
    }

    /// Crea un hint que describe una acción de toggle
    ///
    /// Ejemplo: "Toggles notifications on or off"
    public static func toggles(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Toggles \(what) on or off")
    }

    /// Crea un hint que describe una acción de búsqueda
    public static func searches(_ context: String? = nil) -> AccessibilityHint {
        if let context = context {
            return AccessibilityHint("Searches for \(context)")
        } else {
            return AccessibilityHint("Performs a search")
        }
    }

    /// Crea un hint que describe una acción de filtrado
    public static func filters(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Filters \(what)")
    }

    /// Crea un hint que describe una acción de ordenamiento
    public static func sorts(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Changes sort order of \(what)")
    }

    /// Crea un hint que describe una acción de actualización/refresh
    public static func refreshes(_ what: String = "content") -> AccessibilityHint {
        AccessibilityHint("Refreshes \(what)")
    }

    /// Crea un hint que describe una acción de descarga
    public static func downloads(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Downloads \(what)")
    }

    /// Crea un hint que describe una acción de subida/upload
    public static func uploads(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Uploads \(what)")
    }

    /// Crea un hint que describe cambio de valor en slider/stepper
    public static func adjustsValue(_ what: String) -> AccessibilityHint {
        AccessibilityHint("Adjusts \(what). Swipe up or down to change value")
    }

    /// Crea un hint que describe una acción que requiere confirmación
    public static func requiresConfirmation(_ action: String) -> AccessibilityHint {
        AccessibilityHint("\(action). You will be asked to confirm")
    }
}

// MARK: - Hint Rules

extension AccessibilityHint {
    /// Determina si un hint debería mostrarse según las reglas de mejores prácticas
    ///
    /// Un hint NO debería mostrarse si:
    /// - Duplica información del label
    /// - Es obvio por el contexto
    /// - Describe cómo activar (ej: "Tap to activate")
    public static func shouldShow(
        hint: AccessibilityHint?,
        label: AccessibilityLabel?
    ) -> Bool {
        guard let hint = hint else { return false }

        // Hint vacío → no mostrar
        guard !hint.text.isEmpty else { return false }

        // Si el label ya contiene toda la información del hint → no mostrar
        if let label = label, label.value.lowercased().contains(hint.text.lowercased()) {
            return false
        }

        // Filtrar hints genéricos poco útiles
        let genericHints = [
            "tap to activate",
            "tap to select",
            "double tap",
            "button"
        ]

        let lowercasedHint = hint.text.lowercased()
        for generic in genericHints {
            if lowercasedHint.contains(generic) {
                return false
            }
        }

        return true
    }
}

// MARK: - Predefined Hints (Common Use Cases)

extension AccessibilityHint {
    /// Hints predefinidos comunes para reutilizar en toda la app
    public struct Common {
        // MARK: - Navigation

        public static let opensSettings = AccessibilityHint.opensScreen("settings")
        public static let opensProfile = AccessibilityHint.opensScreen("profile")
        public static let goesBack = AccessibilityHint.text("Returns to the previous screen")
        public static let closesModal = AccessibilityHint.dismisses("this modal")
        public static let closesSheet = AccessibilityHint.dismisses("this sheet")

        // MARK: - Actions

        public static let savesChanges = AccessibilityHint.saves("your changes")
        public static let cancelsAction = AccessibilityHint.text("Cancels the current action")
        public static let deletesItem = AccessibilityHint.deletes("this item", permanent: true)
        public static let editsItem = AccessibilityHint.edits("this item")
        public static let sharesContent = AccessibilityHint.shares("this content")

        // MARK: - Forms

        public static let submitsForm = AccessibilityHint.text("Submits the form")
        public static let clearsInput = AccessibilityHint.text("Clears the input field")
        public static let showsPassword = AccessibilityHint.text("Shows the password as plain text")
        public static let hidesPassword = AccessibilityHint.text("Hides the password")

        // MARK: - Search & Filter

        public static let performsSearch = AccessibilityHint.searches()
        public static let clearsSearch = AccessibilityHint.text("Clears the search query")
        public static let filtersResults = AccessibilityHint.filters("results")
        public static let sortsItems = AccessibilityHint.sorts("items")

        // MARK: - Content Loading

        public static let refreshesContent = AccessibilityHint.refreshes()
        public static let loadsMore = AccessibilityHint.text("Loads more content")

        // MARK: - Media

        public static let playsVideo = AccessibilityHint.text("Plays the video")
        public static let pausesVideo = AccessibilityHint.text("Pauses the video")
        public static let playsAudio = AccessibilityHint.text("Plays the audio")
        public static let pausesAudio = AccessibilityHint.text("Pauses the audio")

        // MARK: - Dangerous Actions

        public static let requiresConfirmationDelete = AccessibilityHint.requiresConfirmation("Deletes this item")
        public static let requiresConfirmationLogout = AccessibilityHint.requiresConfirmation("Logs you out")
    }
}

// MARK: - Hint Validation

extension AccessibilityHint {
    /// Valida que el hint cumpla con las mejores prácticas
    public var isValid: Bool {
        // Hint no debe estar vacío
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // Hint no debe ser excesivamente largo
        guard text.count <= 150 else {
            return false
        }

        // Hint no debe contener instrucciones de activación genéricas
        let forbiddenPhrases = [
            "tap to",
            "double tap",
            "press to",
            "click to",
            "swipe to",
            "activates"
        ]

        let lowercased = text.lowercased()
        for phrase in forbiddenPhrases {
            if lowercased.contains(phrase) {
                return false
            }
        }

        return true
    }

    /// Longitud recomendada para hints (20-80 caracteres)
    public var hasRecommendedLength: Bool {
        (20...80).contains(text.count)
    }

    /// Verifica si el hint describe un resultado (buena práctica)
    /// vs. instrucciones de activación (mala práctica)
    public var describesResult: Bool {
        let resultVerbs = [
            "opens", "closes", "dismisses", "saves", "deletes",
            "edits", "shares", "filters", "sorts", "refreshes",
            "loads", "downloads", "uploads", "plays", "pauses",
            "starts", "stops", "toggles", "adjusts", "changes"
        ]

        let lowercased = text.lowercased()
        return resultVerbs.contains { lowercased.contains($0) }
    }
}

// MARK: - String Extension

extension String {
    /// Convierte un String en AccessibilityHint
    public var asAccessibilityHint: AccessibilityHint {
        AccessibilityHint.text(self)
    }
}

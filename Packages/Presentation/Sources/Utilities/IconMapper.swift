// IconMapper.swift
// EduPresentation
//
// Maps backend Material Icons to SF Symbols.

/// Mapea nombres de Material Icons del backend a SF Symbols.
public struct IconMapper: Sendable {

    private static let mapping: [String: String] = [
        "home": "house.fill",
        "school": "building.columns.fill",
        "people": "person.2.fill",
        "person": "person.fill",
        "settings": "gearshape.fill",
        "assessment": "checkmark.circle.fill",
        "book": "book.fill",
        "folder": "folder.fill",
        "dashboard": "chart.bar.fill",
        "menu_book": "text.book.closed.fill",
        "assignment": "doc.text.fill",
        "group": "person.3.fill",
        "admin_panel_settings": "wrench.and.screwdriver.fill",
        "security": "lock.shield.fill",
        "supervisor_account": "person.badge.shield.checkmark.fill"
    ]

    /// Convierte un nombre de icono del backend a SF Symbol.
    ///
    /// - Parameter backendIcon: Nombre del icono Material del backend.
    /// - Returns: Nombre del SF Symbol correspondiente, o fallback.
    public static func sfSymbol(from backendIcon: String) -> String {
        mapping[backendIcon] ?? "questionmark.circle"
    }
}

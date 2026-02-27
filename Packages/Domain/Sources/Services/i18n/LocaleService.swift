// LocaleService.swift
// EduDomain
//
// Manages the user's preferred locale with persistence and fallback chain.

import Foundation
import EduCore

@MainActor
@Observable
public final class LocaleService {
    private static let localeKey = "com.edugo.locale"

    public private(set) var currentLocale: String

    /// Callback to trigger full sync with new locale.
    public var onLocaleChanged: ((String) async -> Void)?

    public init() {
        self.currentLocale = UserDefaults.standard.string(forKey: Self.localeKey) ?? "es"
    }

    public func changeLocale(_ locale: String) async {
        currentLocale = locale
        UserDefaults.standard.set(locale, forKey: Self.localeKey)
        await onLocaleChanged?(locale)
    }

    /// Fallback chain: es-CO → es → en
    public static func resolvedLocale(from preferred: String) -> String {
        let supported = ["es", "en", "pt-BR"]
        if supported.contains(preferred) { return preferred }
        let base = String(preferred.prefix(2))
        if supported.contains(base) { return base }
        return "en"
    }
}

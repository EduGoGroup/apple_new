//
//  AccessibilityPreferences.swift
//  EduAccessibility
//
//  Centralized observer for all system accessibility preferences.
//
//  Features:
//  - Unified access to all accessibility settings
//  - Computed properties that read current system state
//  - Notification-based updates (optional)
//  - SwiftUI Environment integration
//
//  Tracked Preferences:
//  - Reduce Motion
//  - High Contrast / Increase Contrast
//  - Differentiate Without Color
//  - Content Size Category
//
//  Architecture:
//  - @Observable for reactive updates
//  - @MainActor isolated for thread safety
//  - Computed properties read directly from system
//  - No unnecessary mutable state
//
//  Swift 6.2 strict concurrency compliant
//

import SwiftUI
import Observation

/// Observer centralizado de todas las preferencias de accesibilidad del sistema.
///
/// Arquitectura correcta para Swift 6.2:
/// - Actor aislado al MainActor para acceso seguro
/// - Lee estado actual del sistema bajo demanda
/// - No mantiene estado mutable innecesario
///
/// ## Ejemplo
/// ```swift
/// let prefs = AccessibilityPreferences()
/// let state = await prefs.currentState
/// ```
@MainActor
@Observable
public final class AccessibilityPreferences {

    // MARK: - Singleton

    public static let shared = AccessibilityPreferences()

    // MARK: - Properties (Computed)

    /// Estado actual de Reduce Motion
    public var reduceMotion: Bool {
        ReducedMotionSupport.isEnabled
    }

    /// Estado actual de High Contrast
    public var highContrast: Bool {
        HighContrastSupport.isEnabled
    }

    /// Estado actual de Increase Contrast
    public var increaseContrast: Bool {
        HighContrastSupport.isIncreaseContrastEnabled
    }

    /// Estado actual de Differentiate Without Color
    public var differentiateWithoutColor: Bool {
        HighContrastSupport.isDifferentiateWithoutColorEnabled
    }

    /// Categoría de tamaño de contenido actual
    public var contentSizeCategory: ContentSizeCategory {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory) ?? .medium
        #elseif os(macOS)
        return .medium
        #else
        return .medium
        #endif
    }

    /// Indica si el tamaño actual es de accesibilidad (XL, XXL, XXXL)
    public var isAccessibilitySize: Bool {
        contentSizeCategory.isAccessibilityCategory
    }

    // MARK: - Initialization

    private init() {
        // Setup observers for notifications
        setupObservers()
    }

    // MARK: - Observer Setup

    private func setupObservers() {
        // Reduce Motion notifications
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // @Observable will automatically notify changes
            _ = self?.reduceMotion
        }

        // High Contrast notifications
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.highContrast
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.differentiateWithoutColorDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.differentiateWithoutColor
        }

        // Content Size Category notifications
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.contentSizeCategory
        }
        #elseif os(macOS)
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.highContrast
            _ = self?.reduceMotion
        }
        #endif
    }

    // MARK: - Convenience Methods

    /// Verifica si alguna preferencia de accesibilidad está habilitada
    public var hasAnyAccessibilityPreference: Bool {
        reduceMotion || highContrast || increaseContrast || differentiateWithoutColor || isAccessibilitySize
    }

    /// Verifica si están habilitadas preferencias de contraste
    public var hasContrastPreference: Bool {
        highContrast || increaseContrast
    }

    /// Crea un snapshot del estado actual
    public var currentState: AccessibilityState {
        AccessibilityState(
            reduceMotion: reduceMotion,
            highContrast: highContrast,
            increaseContrast: increaseContrast,
            differentiateWithoutColor: differentiateWithoutColor,
            contentSizeCategory: contentSizeCategory
        )
    }
}

// MARK: - Accessibility State

/// Snapshot del estado de todas las preferencias de accesibilidad
public struct AccessibilityState: Sendable, Equatable {
    public let reduceMotion: Bool
    public let highContrast: Bool
    public let increaseContrast: Bool
    public let differentiateWithoutColor: Bool
    public let contentSizeCategory: ContentSizeCategory

    public init(
        reduceMotion: Bool,
        highContrast: Bool,
        increaseContrast: Bool,
        differentiateWithoutColor: Bool,
        contentSizeCategory: ContentSizeCategory
    ) {
        self.reduceMotion = reduceMotion
        self.highContrast = highContrast
        self.increaseContrast = increaseContrast
        self.differentiateWithoutColor = differentiateWithoutColor
        self.contentSizeCategory = contentSizeCategory
    }

    /// Verifica si alguna preferencia está habilitada
    public var hasAnyPreference: Bool {
        reduceMotion || highContrast || increaseContrast ||
        differentiateWithoutColor || contentSizeCategory.isAccessibilityCategory
    }

    @MainActor
    public static var current: AccessibilityState {
        AccessibilityPreferences.shared.currentState
    }
}

// MARK: - Environment Integration

extension EnvironmentValues {
    /// Estado completo de las preferencias de accesibilidad
    /// Computed property que lee el estado actual
    public var accessibilityPreferences: AccessibilityState {
        get {
            AccessibilityState(
                reduceMotion: self.accessibilityReduceMotion,
                highContrast: self.accessibilityHighContrast,
                increaseContrast: self.accessibilityIncreaseContrast,
                differentiateWithoutColor: self.accessibilityDifferentiateWithoutColor,
                contentSizeCategory: self.sizeCategory
            )
        }
        set {
            self.accessibilityReduceMotion = newValue.reduceMotion
            self.accessibilityHighContrast = newValue.highContrast
            self.accessibilityIncreaseContrast = newValue.increaseContrast
            self.accessibilityDifferentiateWithoutColor = newValue.differentiateWithoutColor
            self.sizeCategory = newValue.contentSizeCategory
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Sincroniza todos los environment values de accesibilidad con el sistema
    /// Agregar a la raíz de la app
    public func syncAccessibilityPreferences() -> some View {
        self
            .syncAccessibilityReduceMotion()
            .syncAccessibilityHighContrast()
    }
}

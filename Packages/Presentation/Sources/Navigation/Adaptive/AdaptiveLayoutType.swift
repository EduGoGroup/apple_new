// AdaptiveLayoutType.swift
// EduPresentation
//
// Defines the adaptive layout categories for responsive navigation.

/// Tipo de layout adaptativo basado en el tamano de pantalla.
public enum AdaptiveLayoutType: Sendable {
    /// iPhone portrait
    case compact

    /// iPhone landscape, iPad split
    case medium

    /// iPad full, Mac
    case expanded
}

// Effects.swift
// Effects
//
// Main export file for the Effects module - iOS 26+ and macOS 26+
//
// This module provides liquid glass effects, visual effects, custom shapes,
// and shadow systems optimized for iOS 26+ and macOS 26+.

@_exported import SwiftUI

// MARK: - Module Documentation

/// # Effects Module
///
/// The Effects module provides a comprehensive set of visual effects for building
/// modern, glass-based user interfaces on iOS 26+ and macOS 26+.
///
/// ## Components
///
/// ### Liquid Glass
/// - `EduLiquidGlassIntensity`: Intensity levels for glass effects
/// - `EduLiquidAnimation`: Animation styles for liquid transitions
/// - `EduGlassState`: Interactive states for glass elements
/// - `EduLiquidGlassConfiguration`: Configuration for glass effects
///
/// ### Visual Effects
/// - `EduVisualEffect`: Protocol for visual effects
/// - `EduVisualEffectStyle`: Predefined effect styles
/// - `EduEffectShape`: Shape options for effects
/// - `EduVisualEffectFactory`: Factory for creating effects
///
/// ### Modifiers
/// - `EduGlassAdaptiveModifier`: Adapts to environment
/// - `EduGlassDepthMappingModifier`: Creates depth perception
/// - `EduGlassRefractionModifier`: Simulates light refraction
/// - `EduLiquidAnimationModifier`: Liquid-like animations
/// - `EduGlassStateModifier`: Interactive state handling
///
/// ### Shapes
/// - `EduLiquidRoundedRectangle`: Smooth liquid corners
/// - `EduMorphableShape`: Shapes that morph between each other
/// - `EduBlobShape`: Organic blob shapes
/// - `EduSquircleShape`: Superellipse shapes
///
/// ### Shadows
/// - `EduShadowLevel`: Predefined shadow levels
/// - `EduShadowConfiguration`: Shadow configuration
/// - `EduGlassAwareShadowModifier`: Glass-aware shadows
/// - `EduLayeredShadowModifier`: Multiple layered shadows
/// - `EduElevationModifier`: Elevation with shadow and scale
///
/// ## Usage
///
/// ```swift
/// import Effects
///
/// struct ContentView: View {
///     var body: some View {
///         Text("Hello, World!")
///             .padding()
///             .eduLiquidGlass(intensity: .standard)
///             .eduShadow(.md)
///     }
/// }
/// ```

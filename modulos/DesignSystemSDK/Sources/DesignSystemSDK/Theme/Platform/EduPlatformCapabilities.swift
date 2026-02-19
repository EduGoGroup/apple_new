// EduPlatformCapabilities.swift
// Theme
//
// Platform capabilities detection for iOS 26+ and macOS 26+

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Detection

/// Sistema de detección de capacidades y características de la plataforma
@available(iOS 26.0, macOS 26.0, *)
public struct EduPlatformCapabilities: Sendable {

    // MARK: - Device Type Detection

    /// Tipo de dispositivo actual
    public enum DeviceType: Sendable {
        case iPhone
        case iPad
        case mac
        case vision
        case unknown
    }

    /// Detecta el tipo de dispositivo actual
    @MainActor
    public static var currentDevice: DeviceType {
        #if os(iOS)
        #if targetEnvironment(simulator)
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        case .vision:
            return .vision
        default:
            return .unknown
        }
        #endif
        #elseif os(macOS)
        return .mac
        #elseif os(visionOS)
        return .vision
        #else
        return .unknown
        #endif
    }

    // MARK: - Size Class Detection

    /// Contexto de Size Class actual
    public struct SizeClassContext: Sendable {
        public let horizontal: UserInterfaceSizeClass?
        public let vertical: UserInterfaceSizeClass?

        public init(horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?) {
            self.horizontal = horizontal
            self.vertical = vertical
        }

        public var isCompact: Bool {
            horizontal == .compact && vertical == .regular
        }

        public var isRegular: Bool {
            horizontal == .regular
        }

        public var isTablet: Bool {
            horizontal == .regular && vertical == .regular
        }
    }

    // MARK: - Screen Capabilities

    public struct ScreenCapabilities: Sendable {
        public let screenSize: CGSize
        public let scale: CGFloat
        public let isLargeScreen: Bool

        public init(screenSize: CGSize, scale: CGFloat, isLargeScreen: Bool) {
            self.screenSize = screenSize
            self.scale = scale
            self.isLargeScreen = isLargeScreen
        }

        public var supportsMultiColumn: Bool {
            isLargeScreen
        }

        public var supportsPermanentSidebar: Bool {
            isLargeScreen
        }
    }

    #if os(iOS)
    @MainActor
    public static var screenCapabilities: ScreenCapabilities {
        let screen = UIScreen.main
        let size = screen.bounds.size
        let scale = screen.scale
        let isLargeScreen = size.width >= 1024 || size.height >= 1024

        return ScreenCapabilities(
            screenSize: size,
            scale: scale,
            isLargeScreen: isLargeScreen
        )
    }
    #elseif os(macOS)
    public static var screenCapabilities: ScreenCapabilities {
        guard let screen = NSScreen.main else {
            return ScreenCapabilities(
                screenSize: CGSize(width: 1920, height: 1080),
                scale: 2.0,
                isLargeScreen: true
            )
        }

        return ScreenCapabilities(
            screenSize: screen.frame.size,
            scale: screen.backingScaleFactor,
            isLargeScreen: true
        )
    }
    #else
    public static var screenCapabilities: ScreenCapabilities {
        ScreenCapabilities(
            screenSize: CGSize(width: 1920, height: 1080),
            scale: 2.0,
            isLargeScreen: true
        )
    }
    #endif

    // MARK: - OS Capabilities

    public struct OSCapabilities: Sendable {
        public let supportsModernEffects: Bool
        public let supportsLiquidGlass: Bool
        public let supportsAdvancedConcurrency: Bool

        public init(
            supportsModernEffects: Bool,
            supportsLiquidGlass: Bool,
            supportsAdvancedConcurrency: Bool
        ) {
            self.supportsModernEffects = supportsModernEffects
            self.supportsLiquidGlass = supportsLiquidGlass
            self.supportsAdvancedConcurrency = supportsAdvancedConcurrency
        }

        public static var current: OSCapabilities {
            // iOS 26+ always supports all modern features
            OSCapabilities(
                supportsModernEffects: true,
                supportsLiquidGlass: true,
                supportsAdvancedConcurrency: true
            )
        }
    }

    // MARK: - Input Capabilities

    public struct InputCapabilities: Sendable {
        public let hasKeyboard: Bool
        public let hasTrackpad: Bool
        public let supportsPencil: Bool
        public let supportsHover: Bool

        public init(
            hasKeyboard: Bool,
            hasTrackpad: Bool,
            supportsPencil: Bool,
            supportsHover: Bool
        ) {
            self.hasKeyboard = hasKeyboard
            self.hasTrackpad = hasTrackpad
            self.supportsPencil = supportsPencil
            self.supportsHover = supportsHover
        }

        @MainActor
        public static var current: InputCapabilities {
            #if os(macOS)
            return InputCapabilities(
                hasKeyboard: true,
                hasTrackpad: true,
                supportsPencil: false,
                supportsHover: true
            )
            #elseif os(iOS)
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            return InputCapabilities(
                hasKeyboard: false,
                hasTrackpad: false,
                supportsPencil: isPad,
                supportsHover: isPad
            )
            #elseif os(visionOS)
            return InputCapabilities(
                hasKeyboard: false,
                hasTrackpad: false,
                supportsPencil: false,
                supportsHover: true
            )
            #else
            return InputCapabilities(
                hasKeyboard: false,
                hasTrackpad: false,
                supportsPencil: false,
                supportsHover: false
            )
            #endif
        }
    }

    // MARK: - Navigation Style

    public enum NavigationStyle: Sendable {
        case tabs
        case sidebar
        case spatial
    }

    @MainActor
    public static var recommendedNavigationStyle: NavigationStyle {
        switch currentDevice {
        case .iPhone:
            return .tabs
        case .iPad, .mac:
            return .sidebar
        case .vision:
            return .spatial
        case .unknown:
            return .tabs
        }
    }

    // MARK: - Convenience Properties

    @MainActor
    public static var isIPhone: Bool {
        currentDevice == .iPhone
    }

    @MainActor
    public static var isIPad: Bool {
        currentDevice == .iPad
    }

    @MainActor
    public static var isMac: Bool {
        currentDevice == .mac
    }

    @MainActor
    public static var isVision: Bool {
        currentDevice == .vision
    }

    @MainActor
    public static var supportsMultipleWindows: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #elseif os(macOS)
        return true
        #elseif os(visionOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - SwiftUI View Extension

@available(iOS 26.0, macOS 26.0, *)
public extension View {
    /// Ejecuta código adaptado según el Size Class context
    func eduAdaptiveLayout<Compact: View, Regular: View>(
        @ViewBuilder compact: @escaping () -> Compact,
        @ViewBuilder regular: @escaping () -> Regular
    ) -> some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width < 768 {
                    compact()
                } else {
                    regular()
                }
            }
        }
    }
}

// MARK: - Compatibility Alias

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduPlatformCapabilities")
public typealias PlatformCapabilities = EduPlatformCapabilities

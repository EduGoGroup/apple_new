// EduFloatingActionButton.swift
// UI
//
// Floating Action Button (FAB) for iOS 26+ and macOS 26+

import SwiftUI

/// Floating Action Button (FAB)
///
/// A prominent button for primary actions, with glass effects
/// and liquid animations optimized for iOS 26+.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduFloatingActionButton: View {
    public let icon: String
    public let label: String?
    public let size: FABSize
    public let tint: Color
    public let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    /// FAB sizes
    public enum FABSize: Sendable {
        /// Mini FAB - 40x40
        case mini
        /// Standard FAB - 56x56
        case standard
        /// Extended FAB - 56 height, variable width with label
        case extended

        public var dimension: CGFloat {
            switch self {
            case .mini: return 40
            case .standard, .extended: return 56
            }
        }

        public var iconSize: Font {
            switch self {
            case .mini: return .title3
            case .standard, .extended: return .title2
            }
        }
    }

    /// Creates a FAB
    ///
    /// - Parameters:
    ///   - icon: SF Symbol icon name
    ///   - label: Label text (only for extended)
    ///   - size: FAB size
    ///   - tint: Tint color
    ///   - action: Action on tap
    public init(
        icon: String,
        label: String? = nil,
        size: FABSize = .standard,
        tint: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.size = size
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: handleAction) {
            fabContent
        }
        .buttonStyle(.plain)
        .background(fabBackground)
        .clipShape(fabShape)
        .shadow(
            color: .black.opacity(isPressed ? 0.1 : 0.2),
            radius: isPressed ? 4 : 8,
            y: isPressed ? 2 : 4
        )
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var fabContent: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: icon)
                .font(size.iconSize)
                .foregroundStyle(.white)

            if size == .extended, let text = label {
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(size == .extended ? DesignTokens.Spacing.large : 0)
        .frame(
            width: size == .extended ? nil : size.dimension,
            height: size.dimension
        )
        .frame(minWidth: size == .extended ? 120 : nil)
    }

    // MARK: - Background

    @ViewBuilder
    private var fabBackground: some View {
        fabShape
            .fill(tint)
            .background(.ultraThinMaterial, in: fabShape)
    }

    private var fabShape: some Shape {
        switch size {
        case .mini, .standard:
            return AnyShape(Circle())
        case .extended:
            return AnyShape(Capsule())
        }
    }

    // MARK: - Actions

    private func handleAction() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        action()
    }
}

// MARK: - FAB Container Helper

/// Helper container to position a FAB on screen
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduFABContainer<Content: View>: View {
    public let position: FABPosition
    @ViewBuilder public let content: () -> Content

    public enum FABPosition: Sendable {
        case bottomTrailing
        case bottomLeading
        case topTrailing
        case topLeading
    }

    public init(position: FABPosition, @ViewBuilder content: @escaping () -> Content) {
        self.position = position
        self.content = content
    }

    public var body: some View {
        VStack {
            if position == .bottomTrailing || position == .bottomLeading {
                Spacer()
            }

            HStack {
                if position == .bottomTrailing || position == .topTrailing {
                    Spacer()
                }

                content()

                if position == .bottomLeading || position == .topLeading {
                    Spacer()
                }
            }

            if position == .topTrailing || position == .topLeading {
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Compatibility Aliases

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduFloatingActionButton")
public typealias DSFloatingActionButton = EduFloatingActionButton

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduFABContainer")
public typealias FABContainer = EduFABContainer

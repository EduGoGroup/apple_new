// EduForm.swift
// UI
//
// Form container with glass background - iOS 26+ and macOS 26+

import SwiftUI

/// Form container with glass background
///
/// Provides a styled form container with glass effects
/// and automatic background handling for iOS 26+.
@available(iOS 26.0, macOS 26.0, *)
public struct EduForm<Content: View>: View {
    @ViewBuilder public let content: () -> Content
    public let onSubmit: () -> Void

    /// Creates a Form with glass background
    ///
    /// - Parameters:
    ///   - onSubmit: Action on form submit
    ///   - content: Form content
    public init(
        onSubmit: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onSubmit = onSubmit
        self.content = content
    }

    public var body: some View {
        Form {
            content()
        }
        .scrollContentBackground(.hidden)
        .glassEffect(.regular)
        .onSubmit(onSubmit)
    }
}

// MARK: - Compatibility Alias

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduForm")
public typealias DSForm = EduForm

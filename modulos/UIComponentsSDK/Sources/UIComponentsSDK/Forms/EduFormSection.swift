// EduFormSection.swift
// UI
//
// Form section with header and footer - iOS 26+ and macOS 26+

import SwiftUI

/// Form section with header and footer
///
/// Provides consistent section styling for forms with
/// optional title and footer text.
@available(iOS 26.0, macOS 26.0, *)
public struct EduFormSection<Content: View>: View {
    public let title: String?
    public let footer: String?
    @ViewBuilder public let content: () -> Content

    /// Creates a form section
    ///
    /// - Parameters:
    ///   - title: Section title (optional)
    ///   - footer: Section footer (optional)
    ///   - content: Section content
    public init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    public var body: some View {
        Section {
            content()
        } header: {
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        } footer: {
            if let footer = footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Compatibility Alias

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduFormSection")
public typealias DSFormSection = EduFormSection

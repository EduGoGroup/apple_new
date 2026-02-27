// EduSplitView.swift
// Navigation
//
// Split View patterns for iOS 26+ and macOS 26+

import SwiftUI

// MARK: - Three Column Split View

/// Split View with 3 columns (Sidebar + Content + Detail)
///
/// Implements Apple's standard 3-column Split View pattern
/// for complex layouts on iPad and Mac with glass effects.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduSplitView<Sidebar: View, Content: View, Detail: View>: View {
    @ViewBuilder public let sidebar: () -> Sidebar
    @ViewBuilder public let content: () -> Content
    @ViewBuilder public let detail: () -> Detail

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Creates a 3-column Split View
    ///
    /// - Parameters:
    ///   - sidebar: Sidebar content
    ///   - content: Middle column content
    ///   - detail: Detail column content
    public init(
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.sidebar = sidebar
        self.content = content
        self.detail = detail
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
                .background(.ultraThinMaterial)
        } content: {
            content()
                .background(.thinMaterial)
        } detail: {
            detail()
        }
    }
}

// MARK: - Two Column Split View

/// Simplified Split View with 2 columns (Sidebar + Detail)
///
/// For layouts that only need sidebar and detail without
/// a middle column.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduTwoColumnSplitView<Sidebar: View, Detail: View>: View {
    @ViewBuilder public let sidebar: () -> Sidebar
    @ViewBuilder public let detail: () -> Detail

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// Creates a 2-column Split View
    ///
    /// - Parameters:
    ///   - sidebar: Sidebar content
    ///   - detail: Detail content
    public init(
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.sidebar = sidebar
        self.detail = detail
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
                .background(.ultraThinMaterial)
        } detail: {
            detail()
        }
    }
}

// MARK: - Adaptive Split View

/// Adaptive Split View that switches between tab and split layout
///
/// Automatically adapts to device size class - uses tabs on iPhone
/// and split view on iPad/Mac.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduAdaptiveSplitView<Sidebar: View, Detail: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ViewBuilder public let sidebar: () -> Sidebar
    @ViewBuilder public let detail: () -> Detail
    public let compactView: AnyView?

    /// Creates an Adaptive Split View
    ///
    /// - Parameters:
    ///   - sidebar: Sidebar content (for regular size class)
    ///   - detail: Detail content
    ///   - compactView: Optional view for compact size class (if nil, uses detail)
    public init(
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder detail: @escaping () -> Detail,
        compactView: AnyView? = nil
    ) {
        self.sidebar = sidebar
        self.detail = detail
        self.compactView = compactView
    }

    public var body: some View {
        if horizontalSizeClass == .compact {
            if let compactView {
                compactView
            } else {
                NavigationStack {
                    detail()
                }
            }
        } else {
            EduTwoColumnSplitView(sidebar: sidebar, detail: detail)
        }
    }
}

// MARK: - Split View Column Width

/// Configuration for split view column widths
@available(iOS 26.0, macOS 26.0, *)
public struct EduSplitViewColumnWidth: Sendable {
    public let min: CGFloat
    public let ideal: CGFloat
    public let max: CGFloat

    public init(min: CGFloat, ideal: CGFloat, max: CGFloat) {
        self.min = min
        self.ideal = ideal
        self.max = max
    }

    /// Standard sidebar width
    public static let sidebar = EduSplitViewColumnWidth(
        min: 200,
        ideal: 250,
        max: 300
    )

    /// Standard content width
    public static let content = EduSplitViewColumnWidth(
        min: 300,
        ideal: 400,
        max: 500
    )

    /// Wide content width
    public static let wideContent = EduSplitViewColumnWidth(
        min: 400,
        ideal: 500,
        max: 600
    )
}

// MARK: - Compatibility Aliases

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduSplitView")
public typealias DSSplitView = EduSplitView

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduTwoColumnSplitView")
public typealias DSTwoColumnSplitView = EduTwoColumnSplitView

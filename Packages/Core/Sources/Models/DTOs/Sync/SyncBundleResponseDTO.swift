// SyncBundleResponseDTO.swift
// Models
//
// Data Transfer Object for the full sync bundle response.

import Foundation

/// Data Transfer Object representing the full sync bundle from the backend.
///
/// This is the top-level response returned on initial sync, containing all
/// navigation, screen definitions, permissions, and available user contexts.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "menu": [ ... ],
///     "permissions": ["view_dashboard", "edit_profile"],
///     "screens": { "dashboard_main": { ... } },
///     "available_contexts": [ ... ],
///     "hashes": { "menu": "abc123", "screens": "def456" }
/// }
/// ```
public struct SyncBundleResponseDTO: Codable, Sendable {
    /// Navigation menu tree.
    public let menu: [MenuItemDTO]

    /// Flat list of granted permission keys.
    public let permissions: [String]

    /// Map of screen keys to their full bundle definitions.
    public let screens: [String: ScreenBundleDTO]

    /// Available user contexts (roles/schools) for context switching.
    public let availableContexts: [UserContextDTO]

    /// Map of bucket names to their current hash values for delta sync.
    public let hashes: [String: String]

    /// Dynamic glossary terms (term_key → localized term value).
    public let glossary: [String: String]?

    /// Server-driven translated strings (string_key → translated value).
    public let strings: [String: String]?

    enum CodingKeys: String, CodingKey {
        case menu
        case permissions
        case screens
        case availableContexts = "available_contexts"
        case hashes
        case glossary
        case strings
    }

    public init(
        menu: [MenuItemDTO],
        permissions: [String],
        screens: [String: ScreenBundleDTO],
        availableContexts: [UserContextDTO],
        hashes: [String: String],
        glossary: [String: String]? = nil,
        strings: [String: String]? = nil
    ) {
        self.menu = menu
        self.permissions = permissions
        self.screens = screens
        self.availableContexts = availableContexts
        self.hashes = hashes
        self.glossary = glossary
        self.strings = strings
    }
}

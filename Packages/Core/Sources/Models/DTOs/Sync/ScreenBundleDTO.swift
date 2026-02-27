// ScreenBundleDTO.swift
// Models
//
// Data Transfer Object for screen bundle definitions from Sync Bundle API.

import Foundation

/// Data Transfer Object representing a screen bundle from the Sync Bundle API.
///
/// Each screen bundle contains the full template definition and optional slot data
/// needed to render a server-driven UI screen.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "screen_key": "dashboard_main",
///     "screen_name": "Dashboard",
///     "pattern": "dashboard",
///     "version": "1.0.0",
///     "template": { ... },
///     "slot_data": { ... },
///     "handler_key": "dashboard_handler"
/// }
/// ```
public struct ScreenBundleDTO: Codable, Sendable, Equatable {
    /// Unique key identifying this screen.
    public let screenKey: String

    /// Human-readable screen name.
    public let screenName: String

    /// Screen pattern type (e.g. "dashboard", "list_detail").
    public let pattern: String

    /// Version string for cache invalidation.
    public let version: String

    /// Full JSON template for rendering the screen.
    public let template: JSONValue

    /// Optional pre-resolved slot data for the screen.
    public let slotData: JSONValue?

    /// Optional handler key for screen-specific logic.
    public let handlerKey: String?

    enum CodingKeys: String, CodingKey {
        case screenKey = "screen_key"
        case screenName = "screen_name"
        case pattern
        case version
        case template
        case slotData = "slot_data"
        case handlerKey = "handler_key"
    }

    public init(
        screenKey: String,
        screenName: String,
        pattern: String,
        version: String,
        template: JSONValue,
        slotData: JSONValue? = nil,
        handlerKey: String? = nil
    ) {
        self.screenKey = screenKey
        self.screenName = screenName
        self.pattern = pattern
        self.version = version
        self.template = template
        self.slotData = slotData
        self.handlerKey = handlerKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        screenKey = try container.decode(String.self, forKey: .screenKey)
        screenName = try container.decode(String.self, forKey: .screenName)
        pattern = try container.decode(String.self, forKey: .pattern)
        // version can be String or Int from the backend
        if let stringVersion = try? container.decode(String.self, forKey: .version) {
            version = stringVersion
        } else if let intVersion = try? container.decode(Int.self, forKey: .version) {
            version = String(intVersion)
        } else {
            version = "0"
        }
        template = try container.decode(JSONValue.self, forKey: .template)
        slotData = try container.decodeIfPresent(JSONValue.self, forKey: .slotData)
        handlerKey = try container.decodeIfPresent(String.self, forKey: .handlerKey)
    }
}

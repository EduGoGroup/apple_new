// ServerStringResolver.swift
// EduDomain
//
// Resolves server-driven translated strings with local fallbacks.

import Foundation
import EduCore

@MainActor
@Observable
public final class ServerStringResolver {
    public private(set) var serverStrings: [String: String] = [:]

    public init() {}

    public func resolve(key: String, fallback: String) -> String {
        serverStrings[key] ?? fallback
    }

    public func updateFromBundle(_ bundle: UserDataBundle) {
        serverStrings = bundle.strings
    }
}

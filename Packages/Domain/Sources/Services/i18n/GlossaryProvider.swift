// GlossaryProvider.swift
// EduDomain
//
// Observable provider that resolves dynamic glossary terms from the sync bundle.

import Foundation
import EduCore

@MainActor
@Observable
public final class GlossaryProvider {
    public private(set) var glossary: [String: String] = [:]

    public init() {}

    public func term(for key: GlossaryKey) -> String {
        glossary[key.rawValue] ?? key.defaultValue
    }

    public func term(for key: String) -> String {
        glossary[key] ?? key
    }

    public func updateFromBundle(_ bundle: UserDataBundle) {
        glossary = bundle.glossary
    }
}

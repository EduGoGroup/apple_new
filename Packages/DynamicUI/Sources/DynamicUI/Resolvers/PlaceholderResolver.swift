import Foundation
import OSLog
import EduModels

/// Informacion de usuario para resolucion de placeholders.
public struct UserPlaceholderInfo: Sendable {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let fullName: String

    public init(firstName: String, lastName: String, email: String, fullName: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.fullName = fullName
    }
}

/// Informacion de contexto para resolucion de placeholders.
public struct ContextPlaceholderInfo: Sendable {
    public let roleName: String
    public let schoolName: String?
    public let academicUnitName: String?

    public init(roleName: String, schoolName: String? = nil, academicUnitName: String? = nil) {
        self.roleName = roleName
        self.schoolName = schoolName
        self.academicUnitName = academicUnitName
    }
}

/// Reemplaza placeholders {_} en strings con valores del contexto.
///
/// Resolution is defensive: if an individual token fails to resolve,
/// it is left as-is in the output string rather than causing a crash.
public struct PlaceholderResolver: Sendable {
    private static let logger = os.Logger(
        subsystem: "com.edugo.dynamicui",
        category: "PlaceholderResolver"
    )

    public let userInfo: UserPlaceholderInfo
    public let contextInfo: ContextPlaceholderInfo
    public let glossaryData: [String: String]

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    public init(userInfo: UserPlaceholderInfo, contextInfo: ContextPlaceholderInfo, glossaryData: [String: String] = [:]) {
        self.userInfo = userInfo
        self.contextInfo = contextInfo
        self.glossaryData = glossaryData
    }

    /// Reemplaza placeholders en un string de forma defensiva.
    ///
    /// Si un token individual no puede resolverse, se deja tal cual en el resultado.
    public func resolve(_ text: String, itemData: [String: JSONValue]? = nil) -> String {
        var result = text

        // User placeholders
        result = safeReplace(result, token: "{user.firstName}", with: userInfo.firstName)
        result = safeReplace(result, token: "{user.lastName}", with: userInfo.lastName)
        result = safeReplace(result, token: "{user.email}", with: userInfo.email)
        result = safeReplace(result, token: "{user.fullName}", with: userInfo.fullName)

        // Context placeholders
        result = safeReplace(result, token: "{context.roleName}", with: contextInfo.roleName)
        result = safeReplace(result, token: "{context.schoolName}", with: contextInfo.schoolName ?? "")
        result = safeReplace(result, token: "{context.academicUnitName}", with: contextInfo.academicUnitName ?? "")

        // Glossary placeholders {glossary.*}
        for (key, value) in glossaryData {
            result = safeReplace(result, token: "{glossary.\(key)}", with: value)
        }

        // Date placeholders
        result = safeReplace(result, token: "{today_date}", with: Self.dateFormatter.string(from: Date()))
        result = safeReplace(
            result,
            token: "{current_year}",
            with: String(Calendar.current.component(.year, from: Date()))
        )

        // Item data placeholders {item.fieldName}
        if let itemData {
            for (key, value) in itemData {
                result = safeReplace(result, token: "{item.\(key)}", with: value.stringRepresentation)
            }
        }

        return result
    }

    /// Safely replaces a token in the text. If replacement fails for any reason,
    /// the original text is returned unchanged and a warning is logged.
    private func safeReplace(_ text: String, token: String, with replacement: String) -> String {
        guard text.contains(token) else { return text }
        let replaced = text.replacingOccurrences(of: token, with: replacement)
        if replaced == text {
            Self.logger.error("[PlaceholderResolver] Failed to replace token '\(token)'")
        }
        return replaced
    }
}

import Foundation
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
public struct PlaceholderResolver: Sendable {
    public let userInfo: UserPlaceholderInfo
    public let contextInfo: ContextPlaceholderInfo

    public init(userInfo: UserPlaceholderInfo, contextInfo: ContextPlaceholderInfo) {
        self.userInfo = userInfo
        self.contextInfo = contextInfo
    }

    /// Reemplaza placeholders en un string.
    public func resolve(_ text: String, itemData: [String: JSONValue]? = nil) -> String {
        var result = text

        // User placeholders
        result = result.replacingOccurrences(of: "{user.firstName}", with: userInfo.firstName)
        result = result.replacingOccurrences(of: "{user.lastName}", with: userInfo.lastName)
        result = result.replacingOccurrences(of: "{user.email}", with: userInfo.email)
        result = result.replacingOccurrences(of: "{user.fullName}", with: userInfo.fullName)

        // Context placeholders
        result = result.replacingOccurrences(of: "{context.roleName}", with: contextInfo.roleName)
        result = result.replacingOccurrences(of: "{context.schoolName}", with: contextInfo.schoolName ?? "")
        result = result.replacingOccurrences(of: "{context.academicUnitName}", with: contextInfo.academicUnitName ?? "")

        // Date placeholders
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        result = result.replacingOccurrences(of: "{today_date}", with: formatter.string(from: Date()))
        result = result.replacingOccurrences(of: "{current_year}", with: String(Calendar.current.component(.year, from: Date())))

        // Item data placeholders {item.fieldName}
        if let itemData {
            for (key, value) in itemData {
                result = result.replacingOccurrences(of: "{item.\(key)}", with: value.stringRepresentation)
            }
        }

        return result
    }
}

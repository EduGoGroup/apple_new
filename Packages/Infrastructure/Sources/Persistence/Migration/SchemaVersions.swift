import Foundation
import SwiftData

// MARK: - Schema Version 1

/// Schema V1: Original schema with UserModel and DocumentModel
///
/// This version represents the initial schema before the backend alignment changes.
/// - UserModel had `name` (single field) and `roleIDs`
/// - DocumentModel for text documents
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [UserModel.self, DocumentModel.self]
    }
}

// MARK: - Schema Version 2

/// Schema V2: Backend-aligned schema with all persistence models
///
/// Changes from V1:
/// - UserModel now uses `firstName`/`lastName` instead of `name`
/// - UserModel no longer has `roleIDs` (roles managed via Membership)
/// - Added MaterialModel for educational files
/// - Added SchoolModel for schools
/// - Added AcademicUnitModel for organizational units
/// - Added MembershipModel for user-unit-role relationships
public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [
            UserModel.self,
            DocumentModel.self,
            MaterialModel.self,
            SchoolModel.self,
            AcademicUnitModel.self,
            MembershipModel.self
        ]
    }
}

// MARK: - Current Schema

/// The current schema version used by the application
public typealias CurrentSchema = SchemaV2

/// Convenience property to get all current model types
public var allModelTypes: [any PersistentModel.Type] {
    CurrentSchema.models
}

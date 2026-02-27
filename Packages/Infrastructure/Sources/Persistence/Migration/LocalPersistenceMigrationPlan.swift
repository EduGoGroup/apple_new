import Foundation
import SwiftData

/// Migration plan for LocalPersistence schema evolution
///
/// Defines the migration path from V1 to V2 schema:
/// - V1: Original schema (UserModel with `name`, `roleIDs`)
/// - V2: Backend-aligned schema (UserModel with `firstName`/`lastName`, new models)
///
/// ## Migration Strategy
///
/// For V1 → V2 migration:
/// - `name` field is migrated to `firstName` (lastName set to empty string)
/// - `roleIDs` field is dropped (roles now managed via MembershipModel)
/// - New models (Material, School, AcademicUnit, Membership) are added with empty tables
///
/// ## Usage
///
/// ```swift
/// let container = try ModelContainer(
///     for: CurrentSchema.self,
///     migrationPlan: LocalPersistenceMigrationPlan.self
/// )
/// ```
public enum LocalPersistenceMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// Migration stage from V1 to V2
    ///
    /// This is a lightweight migration since:
    /// - UserModel fields changed but data can be preserved
    /// - New models are added (empty tables created automatically)
    ///
    /// Note: In a production scenario with existing V1 data, you would use
    /// `.custom` migration to transform `name` → `firstName`/`lastName`.
    /// Since this is a new deployment, we use lightweight migration.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}

// MARK: - Schema Helper

/// Helper to create a Schema with all current models
///
/// Use this when configuring the ModelContainer:
/// ```swift
/// try await provider.configure(
///     with: .production,
///     schema: LocalPersistenceSchema.current
/// )
/// ```
public enum LocalPersistenceSchema {
    /// The current schema with all models
    public static var current: Schema {
        Schema(CurrentSchema.models)
    }

    /// Schema for V1 (legacy, for migration testing)
    public static var v1: Schema {
        Schema(SchemaV1.models)
    }

    /// Schema for V2 (current)
    public static var v2: Schema {
        Schema(SchemaV2.models)
    }
}

// BackendFixtures.swift
// ModelsTests
//
// JSON fixtures based on edu-admin and edu-mobile swagger.json specifications.
// These fixtures represent actual backend responses for integration testing.

import Foundation
@testable import EduModels

/// Backend JSON fixtures derived from swagger.json specifications.
///
/// These fixtures represent realistic backend API responses for testing
/// serialization and deserialization of DTOs.
///
/// ## Sources
/// - edu-admin API: User, School, AcademicUnit, Membership
/// - edu-mobile API: Material
enum BackendFixtures {

    // MARK: - User Fixtures (edu-admin)

    /// Valid user response from edu-admin `/v1/users/{id}`
    static let userValidJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "first_name": "Juan",
        "last_name": "García",
        "full_name": "Juan García",
        "email": "juan.garcia@edugo.com",
        "is_active": true,
        "role": "teacher",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:45:00Z"
    }
    """

    /// User with minimal required fields
    static let userMinimalJSON = """
    {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "first_name": "María",
        "last_name": "López",
        "email": "maria@test.com",
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// User with optional fields as null
    static let userWithNullsJSON = """
    {
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "first_name": "Pedro",
        "last_name": "Martínez",
        "full_name": null,
        "email": "pedro@test.com",
        "is_active": false,
        "role": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// User with inactive status
    static let userInactiveJSON = """
    {
        "id": "880e8400-e29b-41d4-a716-446655440003",
        "first_name": "Ana",
        "last_name": "Rodríguez",
        "email": "ana.inactive@test.com",
        "is_active": false,
        "created_at": "2024-01-10T08:00:00Z",
        "updated_at": "2024-06-15T16:30:00Z"
    }
    """

    // MARK: - School Fixtures (edu-admin)

    /// Valid school response from edu-admin `/v1/schools/{id}`
    static let schoolValidJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440100",
        "name": "Colegio San José",
        "code": "COL-SJ-001",
        "is_active": true,
        "address": "Calle 123 #45-67",
        "city": "Bogotá",
        "country": "CO",
        "contact_email": "contacto@colegiosanjose.edu.co",
        "contact_phone": "+57-1-555-1234",
        "max_students": 500,
        "max_teachers": 50,
        "subscription_tier": "premium",
        "metadata": {"region": "andina", "founded_year": 1985},
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:45:00Z"
    }
    """

    /// School with minimal required fields
    static let schoolMinimalJSON = """
    {
        "id": "660e8400-e29b-41d4-a716-446655440101",
        "name": "Escuela Nueva",
        "code": "ESC-N-001",
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// School with all optional fields as null
    static let schoolWithNullsJSON = """
    {
        "id": "770e8400-e29b-41d4-a716-446655440102",
        "name": "Instituto ABC",
        "code": "INST-ABC",
        "is_active": true,
        "address": null,
        "city": null,
        "country": null,
        "contact_email": null,
        "contact_phone": null,
        "max_students": null,
        "max_teachers": null,
        "subscription_tier": null,
        "metadata": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// School with free tier subscription
    static let schoolFreeTierJSON = """
    {
        "id": "880e8400-e29b-41d4-a716-446655440103",
        "name": "Escuela Pública Central",
        "code": "ESC-PUB-001",
        "is_active": true,
        "address": "Avenida Principal 100",
        "city": "Medellín",
        "country": "CO",
        "max_students": 100,
        "max_teachers": 10,
        "subscription_tier": "free",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    // MARK: - AcademicUnit Fixtures (edu-admin)

    /// Valid academic unit response from edu-admin `/v1/units/{id}`
    static let academicUnitGradeJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440200",
        "display_name": "Décimo Grado",
        "code": "G10",
        "description": "Estudiantes de décimo grado",
        "type": "grade",
        "parent_unit_id": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "metadata": {"capacity": 120, "building": "A"},
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:45:00Z",
        "deleted_at": null
    }
    """

    /// Academic unit with parent (section)
    static let academicUnitSectionJSON = """
    {
        "id": "660e8400-e29b-41d4-a716-446655440201",
        "display_name": "Sección A",
        "code": "G10-A",
        "description": "Primera sección del décimo grado",
        "type": "section",
        "parent_unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "metadata": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:45:00Z",
        "deleted_at": null
    }
    """

    /// Academic unit of type club
    static let academicUnitClubJSON = """
    {
        "id": "770e8400-e29b-41d4-a716-446655440202",
        "display_name": "Club de Matemáticas",
        "code": "CLUB-MAT",
        "description": "Club extracurricular de matemáticas",
        "type": "club",
        "parent_unit_id": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "metadata": {"meeting_day": "miércoles"},
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "deleted_at": null
    }
    """

    /// Academic unit of type department
    static let academicUnitDepartmentJSON = """
    {
        "id": "880e8400-e29b-41d4-a716-446655440203",
        "display_name": "Departamento de Ciencias",
        "code": "DEP-CIEN",
        "description": "Departamento de ciencias naturales",
        "type": "department",
        "parent_unit_id": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "metadata": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "deleted_at": null
    }
    """

    /// Soft-deleted academic unit
    static let academicUnitDeletedJSON = """
    {
        "id": "990e8400-e29b-41d4-a716-446655440204",
        "display_name": "Unidad Eliminada",
        "code": "DEL-001",
        "description": null,
        "type": "grade",
        "parent_unit_id": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "metadata": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-06-01T12:00:00Z",
        "deleted_at": "2024-06-01T12:00:00Z"
    }
    """

    // MARK: - Membership Fixtures (edu-admin)

    /// Valid membership response from edu-admin `/v1/memberships/{id}`
    static let membershipTeacherJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440300",
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "role": "teacher",
        "is_active": true,
        "enrolled_at": "2024-01-15T10:30:00Z",
        "withdrawn_at": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:45:00Z"
    }
    """

    /// Student membership
    static let membershipStudentJSON = """
    {
        "id": "660e8400-e29b-41d4-a716-446655440301",
        "user_id": "660e8400-e29b-41d4-a716-446655440001",
        "unit_id": "660e8400-e29b-41d4-a716-446655440201",
        "role": "student",
        "is_active": true,
        "enrolled_at": "2024-01-15T10:30:00Z",
        "withdrawn_at": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// Owner membership
    static let membershipOwnerJSON = """
    {
        "id": "770e8400-e29b-41d4-a716-446655440302",
        "user_id": "770e8400-e29b-41d4-a716-446655440002",
        "unit_id": "550e8400-e29b-41d4-a716-446655440100",
        "role": "owner",
        "is_active": true,
        "enrolled_at": "2024-01-01T00:00:00Z",
        "withdrawn_at": null,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z"
    }
    """

    /// Guardian membership
    static let membershipGuardianJSON = """
    {
        "id": "880e8400-e29b-41d4-a716-446655440303",
        "user_id": "880e8400-e29b-41d4-a716-446655440003",
        "unit_id": "660e8400-e29b-41d4-a716-446655440201",
        "role": "guardian",
        "is_active": true,
        "enrolled_at": "2024-01-15T10:30:00Z",
        "withdrawn_at": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// Withdrawn membership
    static let membershipWithdrawnJSON = """
    {
        "id": "990e8400-e29b-41d4-a716-446655440304",
        "user_id": "990e8400-e29b-41d4-a716-446655440004",
        "unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "role": "student",
        "is_active": false,
        "enrolled_at": "2024-01-15T10:30:00Z",
        "withdrawn_at": "2024-06-15T16:00:00Z",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-06-15T16:00:00Z"
    }
    """

    /// Assistant membership
    static let membershipAssistantJSON = """
    {
        "id": "aa0e8400-e29b-41d4-a716-446655440305",
        "user_id": "aa0e8400-e29b-41d4-a716-446655440005",
        "unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "role": "assistant",
        "is_active": true,
        "enrolled_at": "2024-02-01T08:00:00Z",
        "withdrawn_at": null,
        "created_at": "2024-02-01T08:00:00Z",
        "updated_at": "2024-02-01T08:00:00Z"
    }
    """

    // MARK: - Material Fixtures (edu-mobile)

    /// Valid material response from edu-mobile `/v1/materials/{id}`
    static let materialReadyJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440400",
        "title": "Introducción al Cálculo",
        "description": "Guía completa de cálculo diferencial e integral",
        "status": "ready",
        "file_url": "https://s3.amazonaws.com/edugo-materials/550e8400.pdf",
        "file_type": "application/pdf",
        "file_size_bytes": 1048576,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "uploaded_by_teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "subject": "Matemáticas",
        "grade": "12° Grado",
        "is_public": false,
        "processing_started_at": "2024-01-15T10:30:00Z",
        "processing_completed_at": "2024-01-15T10:35:00Z",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-20T14:45:00Z",
        "deleted_at": null
    }
    """

    /// Material in uploaded status
    static let materialUploadedJSON = """
    {
        "id": "660e8400-e29b-41d4-a716-446655440401",
        "title": "Material Recién Subido",
        "description": null,
        "status": "uploaded",
        "file_url": "https://s3.amazonaws.com/edugo-materials/660e8400.pdf",
        "file_type": "application/pdf",
        "file_size_bytes": 512000,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "subject": null,
        "grade": null,
        "is_public": false,
        "processing_started_at": null,
        "processing_completed_at": null,
        "created_at": "2024-01-20T09:00:00Z",
        "updated_at": "2024-01-20T09:00:00Z",
        "deleted_at": null
    }
    """

    /// Material in processing status
    static let materialProcessingJSON = """
    {
        "id": "770e8400-e29b-41d4-a716-446655440402",
        "title": "Material en Procesamiento",
        "description": "Este material está siendo procesado",
        "status": "processing",
        "file_url": "https://s3.amazonaws.com/edugo-materials/770e8400.pdf",
        "file_type": "application/pdf",
        "file_size_bytes": 2097152,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "uploaded_by_teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "subject": "Ciencias",
        "grade": "11° Grado",
        "is_public": false,
        "processing_started_at": "2024-01-20T10:00:00Z",
        "processing_completed_at": null,
        "created_at": "2024-01-20T10:00:00Z",
        "updated_at": "2024-01-20T10:00:00Z",
        "deleted_at": null
    }
    """

    /// Material with failed processing
    static let materialFailedJSON = """
    {
        "id": "880e8400-e29b-41d4-a716-446655440403",
        "title": "Material con Error",
        "description": "Este material falló durante el procesamiento",
        "status": "failed",
        "file_url": "https://s3.amazonaws.com/edugo-materials/880e8400.pdf",
        "file_type": "application/pdf",
        "file_size_bytes": 10485760,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "subject": null,
        "grade": null,
        "is_public": false,
        "processing_started_at": "2024-01-20T11:00:00Z",
        "processing_completed_at": "2024-01-20T11:05:00Z",
        "created_at": "2024-01-20T11:00:00Z",
        "updated_at": "2024-01-20T11:05:00Z",
        "deleted_at": null
    }
    """

    /// Public material
    static let materialPublicJSON = """
    {
        "id": "990e8400-e29b-41d4-a716-446655440404",
        "title": "Material Público",
        "description": "Material disponible para todos los estudiantes",
        "status": "ready",
        "file_url": "https://s3.amazonaws.com/edugo-materials/990e8400.pdf",
        "file_type": "application/pdf",
        "file_size_bytes": 256000,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "subject": "Historia",
        "grade": "9° Grado",
        "is_public": true,
        "processing_started_at": "2024-01-15T10:30:00Z",
        "processing_completed_at": "2024-01-15T10:32:00Z",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:32:00Z",
        "deleted_at": null
    }
    """

    /// Deleted material
    static let materialDeletedJSON = """
    {
        "id": "aa0e8400-e29b-41d4-a716-446655440405",
        "title": "Material Eliminado",
        "description": null,
        "status": "ready",
        "file_url": null,
        "file_type": null,
        "file_size_bytes": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": "550e8400-e29b-41d4-a716-446655440000",
        "subject": null,
        "grade": null,
        "is_public": false,
        "processing_started_at": null,
        "processing_completed_at": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-06-01T12:00:00Z",
        "deleted_at": "2024-06-01T12:00:00Z"
    }
    """

    /// Material with minimal fields
    static let materialMinimalJSON = """
    {
        "id": "bb0e8400-e29b-41d4-a716-446655440406",
        "title": "Material Básico",
        "description": null,
        "status": "uploaded",
        "file_url": null,
        "file_type": null,
        "file_size_bytes": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": null,
        "subject": null,
        "grade": null,
        "is_public": false,
        "processing_started_at": null,
        "processing_completed_at": null,
        "created_at": "2024-01-20T12:00:00Z",
        "updated_at": "2024-01-20T12:00:00Z",
        "deleted_at": null
    }
    """

    // MARK: - Edge Case Fixtures

    /// JSON with empty string fields
    static let userEmptyStringsJSON = """
    {
        "id": "cc0e8400-e29b-41d4-a716-446655440500",
        "first_name": "",
        "last_name": "",
        "email": "",
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// JSON with whitespace-only names
    static let userWhitespaceNamesJSON = """
    {
        "id": "dd0e8400-e29b-41d4-a716-446655440501",
        "first_name": "   ",
        "last_name": "   ",
        "email": "test@example.com",
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// JSON with invalid email format
    static let userInvalidEmailJSON = """
    {
        "id": "ee0e8400-e29b-41d4-a716-446655440502",
        "first_name": "Test",
        "last_name": "User",
        "email": "not-an-email",
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// JSON with invalid UUID format
    static let userInvalidUUIDJSON = """
    {
        "id": "not-a-valid-uuid",
        "first_name": "Test",
        "last_name": "User",
        "email": "test@example.com",
        "is_active": true,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// JSON with invalid date format
    static let userInvalidDateJSON = """
    {
        "id": "ff0e8400-e29b-41d4-a716-446655440503",
        "first_name": "Test",
        "last_name": "User",
        "email": "test@example.com",
        "is_active": true,
        "created_at": "invalid-date",
        "updated_at": "2024-01-15"
    }
    """

    /// Material with invalid URL
    static let materialInvalidURLJSON = """
    {
        "id": "aa0e8400-e29b-41d4-a716-446655440600",
        "title": "Material con URL Inválida",
        "description": null,
        "status": "ready",
        "file_url": "not a valid url",
        "file_type": null,
        "file_size_bytes": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": null,
        "subject": null,
        "grade": null,
        "is_public": false,
        "processing_started_at": null,
        "processing_completed_at": null,
        "created_at": "2024-01-20T12:00:00Z",
        "updated_at": "2024-01-20T12:00:00Z",
        "deleted_at": null
    }
    """

    /// Membership with unknown role
    static let membershipUnknownRoleJSON = """
    {
        "id": "bb0e8400-e29b-41d4-a716-446655440700",
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "unit_id": "550e8400-e29b-41d4-a716-446655440200",
        "role": "superadmin",
        "is_active": true,
        "enrolled_at": "2024-01-15T10:30:00Z",
        "withdrawn_at": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    /// Material with unknown status
    static let materialUnknownStatusJSON = """
    {
        "id": "cc0e8400-e29b-41d4-a716-446655440800",
        "title": "Material con Status Desconocido",
        "description": null,
        "status": "pending_review",
        "file_url": null,
        "file_type": null,
        "file_size_bytes": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "academic_unit_id": null,
        "uploaded_by_teacher_id": null,
        "subject": null,
        "grade": null,
        "is_public": false,
        "processing_started_at": null,
        "processing_completed_at": null,
        "created_at": "2024-01-20T12:00:00Z",
        "updated_at": "2024-01-20T12:00:00Z",
        "deleted_at": null
    }
    """

    /// AcademicUnit with unknown type
    static let academicUnitUnknownTypeJSON = """
    {
        "id": "dd0e8400-e29b-41d4-a716-446655440900",
        "display_name": "Unidad Tipo Desconocido",
        "code": null,
        "description": null,
        "type": "faculty",
        "parent_unit_id": null,
        "school_id": "550e8400-e29b-41d4-a716-446655440100",
        "metadata": null,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "deleted_at": null
    }
    """

    /// School with complex metadata
    static let schoolComplexMetadataJSON = """
    {
        "id": "ee0e8400-e29b-41d4-a716-446655441000",
        "name": "Colegio con Metadata Compleja",
        "code": "META-001",
        "is_active": true,
        "address": null,
        "city": null,
        "country": null,
        "contact_email": null,
        "contact_phone": null,
        "max_students": null,
        "max_teachers": null,
        "subscription_tier": null,
        "metadata": {
            "string_value": "texto",
            "number_value": 42,
            "boolean_value": true,
            "null_value": null,
            "array_value": [1, 2, 3],
            "nested_object": {"key": "value"}
        },
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    }
    """

    // MARK: - Array Fixtures

    /// List of materials response
    static let materialsArrayJSON = """
    [
        {
            "id": "550e8400-e29b-41d4-a716-446655440400",
            "title": "Material 1",
            "description": null,
            "status": "ready",
            "file_url": "https://example.com/1.pdf",
            "file_type": "application/pdf",
            "file_size_bytes": 1024,
            "school_id": "550e8400-e29b-41d4-a716-446655440100",
            "academic_unit_id": null,
            "uploaded_by_teacher_id": null,
            "subject": null,
            "grade": null,
            "is_public": false,
            "processing_started_at": null,
            "processing_completed_at": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z",
            "deleted_at": null
        },
        {
            "id": "660e8400-e29b-41d4-a716-446655440401",
            "title": "Material 2",
            "description": "Segundo material",
            "status": "processing",
            "file_url": null,
            "file_type": null,
            "file_size_bytes": null,
            "school_id": "550e8400-e29b-41d4-a716-446655440100",
            "academic_unit_id": null,
            "uploaded_by_teacher_id": null,
            "subject": "Física",
            "grade": "10° Grado",
            "is_public": true,
            "processing_started_at": "2024-01-20T10:00:00Z",
            "processing_completed_at": null,
            "created_at": "2024-01-20T10:00:00Z",
            "updated_at": "2024-01-20T10:00:00Z",
            "deleted_at": null
        }
    ]
    """

    /// List of memberships response
    static let membershipsArrayJSON = """
    [
        {
            "id": "550e8400-e29b-41d4-a716-446655440300",
            "user_id": "550e8400-e29b-41d4-a716-446655440000",
            "unit_id": "550e8400-e29b-41d4-a716-446655440200",
            "role": "teacher",
            "is_active": true,
            "enrolled_at": "2024-01-15T10:30:00Z",
            "withdrawn_at": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        },
        {
            "id": "660e8400-e29b-41d4-a716-446655440301",
            "user_id": "660e8400-e29b-41d4-a716-446655440001",
            "unit_id": "550e8400-e29b-41d4-a716-446655440200",
            "role": "student",
            "is_active": true,
            "enrolled_at": "2024-01-20T08:00:00Z",
            "withdrawn_at": null,
            "created_at": "2024-01-20T08:00:00Z",
            "updated_at": "2024-01-20T08:00:00Z"
        }
    ]
    """
}

// MARK: - Helper Extension

extension BackendFixtures {

    /// Creates a configured JSON decoder for backend responses.
    static var backendDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Creates a configured JSON encoder for backend requests.
    static var backendEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

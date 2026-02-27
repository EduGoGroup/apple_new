// GlossaryKey.swift
// EduDomain
//
// Enum of known glossary term keys with their default Spanish values.

public enum GlossaryKey: String, CaseIterable, Sendable {
    case orgNameSingular = "org.name_singular"
    case orgNamePlural = "org.name_plural"
    case unitLevel1 = "unit.level1"
    case unitLevel2 = "unit.level2"
    case unitPeriod = "unit.period"
    case memberStudent = "member.student"
    case memberStudentPlural = "member.student_plural"
    case memberTeacher = "member.teacher"
    case memberTeacherPlural = "member.teacher_plural"
    case memberGuardian = "member.guardian"
    case memberCoordinator = "member.coordinator"
    case memberAdmin = "member.admin"
    case contentSubject = "content.subject"
    case contentAssessment = "content.assessment"
    case contentMaterial = "content.material"
    case contentGrade = "content.grade"

    public var defaultValue: String {
        switch self {
        case .orgNameSingular: "Institución"
        case .orgNamePlural: "Instituciones"
        case .unitLevel1: "Grado"
        case .unitLevel2: "Sección"
        case .unitPeriod: "Periodo"
        case .memberStudent: "Estudiante"
        case .memberStudentPlural: "Estudiantes"
        case .memberTeacher: "Docente"
        case .memberTeacherPlural: "Docentes"
        case .memberGuardian: "Acudiente"
        case .memberCoordinator: "Coordinador"
        case .memberAdmin: "Administrador"
        case .contentSubject: "Materia"
        case .contentAssessment: "Evaluación"
        case .contentMaterial: "Material"
        case .contentGrade: "Nota"
        }
    }
}

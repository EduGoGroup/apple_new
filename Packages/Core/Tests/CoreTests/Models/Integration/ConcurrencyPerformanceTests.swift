import Testing
import Foundation
@testable import EduModels

/// Performance tests for domain entities under high-concurrency scenarios.
///
/// These tests measure:
/// 1. Performance impact of value semantics (copy-on-write)
/// 2. Throughput under load (1000+ operations)
/// 3. Memory behavior with large entity graphs
@Suite("Concurrency Performance Tests")
struct ConcurrencyPerformanceTests {

    // MARK: - High-Volume Operations

    @Test("1000+ User copy operations complete quickly")
    func testMassiveUserCopyOperations() async throws {
        let baseUser = try User(
            firstName: "Performance",
            lastName: "Test User",
            email: "perf@test.com"
        )

        let startTime = ContinuousClock.now

        // Perform 1000 concurrent copy operations
        let results = await withTaskGroup(of: User.self, returning: [User].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var modified = try! baseUser.with(firstName: "User\(i)")
                    // Simulate typical modifications
                    if i % 2 == 0 {
                        modified = modified.with(isActive: false)
                    }
                    return modified
                }
            }

            var results: [User] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        // Should complete in under 2 seconds
        #expect(elapsed < .seconds(2), "Operations took too long: \(elapsed)")
    }

    @Test("1000+ Role operations with permission management")
    func testMassiveRoleOperations() async throws {
        let permissionIDs = (0..<10).map { _ in UUID() }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Role.self, returning: [Role].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var role = try! Role(
                        name: "Role \(i)",
                        level: RoleLevel.allCases[i % 3]
                    )

                    // Add multiple permissions
                    for permID in permissionIDs.prefix(i % 10 + 1) {
                        role = role.addPermission(permID)
                    }

                    return role
                }
            }

            var results: [Role] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "Operations took too long: \(elapsed)")
    }

    @Test("1000+ Document lifecycle operations")
    func testMassiveDocumentOperations() async throws {
        let ownerID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Document?.self, returning: [Document].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    guard let doc = try? Document(
                        title: "Doc \(i)",
                        content: "Content \(i)",
                        type: DocumentType.allCases[i % DocumentType.allCases.count],
                        ownerID: ownerID
                    ) else { return nil }

                    // Add some collaborators
                    var modified = doc
                    for _ in 0..<(i % 5) {
                        modified = modified.addCollaborator(UUID())
                    }

                    // Update content
                    modified = modified.with(content: "Updated content \(i)")

                    return modified
                }
            }

            var results: [Document] = []
            results.reserveCapacity(1000)
            for await result in group {
                if let doc = result {
                    results.append(doc)
                }
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "Operations took too long: \(elapsed)")
    }

    // MARK: - Large Graph Performance

    @Test("Large entity graph construction performance")
    func testLargeGraphConstruction() async throws {
        let startTime = ContinuousClock.now

        // Create a large permission set
        let permissions = await withTaskGroup(of: Permission.self, returning: [Permission].self) { group in
            for resource in Resource.allCases {
                for action in Action.allCases {
                    group.addTask {
                        Permission.create(resource: resource, action: action)
                    }
                }
            }

            var results: [Permission] = []
            for await perm in group {
                results.append(perm)
            }
            return results
        }

        // Create roles with permissions
        let roles = await withTaskGroup(of: Role.self, returning: [Role].self) { group in
            for i in 0..<50 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var role = try! Role(
                        name: "Role \(i)",
                        level: RoleLevel.allCases[i % 3]
                    )
                    for perm in permissions.prefix(permissions.count / 2) {
                        role = role.addPermission(perm.id)
                    }
                    return role
                }
            }

            var results: [Role] = []
            for await role in group {
                results.append(role)
            }
            return results
        }

        // Create users (roles are now managed via Membership, not stored in User)
        let users = await withTaskGroup(of: User.self, returning: [User].self) { group in
            for i in 0..<100 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    try! User(
                        firstName: "User",
                        lastName: "\(i)",
                        email: "user\(i)@perf.test"
                    )
                }
            }

            var results: [User] = []
            for await user in group {
                results.append(user)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        // Verify graph construction
        #expect(permissions.count == Resource.allCases.count * Action.allCases.count)
        #expect(roles.count == 50)
        #expect(users.count == 100)
        #expect(elapsed < .seconds(2), "Graph construction took too long: \(elapsed)")
    }

    // MARK: - Read-Heavy Workload

    @Test("Read-heavy concurrent access performance")
    func testReadHeavyWorkload() async throws {
        // Setup: Create a user
        // swiftlint:disable:next force_try
        let user = try! User(firstName: "Read", lastName: "Test", email: "read@test.com")

        let startTime = ContinuousClock.now

        // Perform 5000 concurrent reads
        let results = await withTaskGroup(
            of: (fullName: String, email: String).self,
            returning: [(fullName: String, email: String)].self
        ) { group in
            for _ in 0..<5000 {
                group.addTask {
                    (user.fullName, user.email)
                }
            }

            var results: [(fullName: String, email: String)] = []
            results.reserveCapacity(5000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 5000)
        #expect(results.allSatisfy { $0.fullName == "Read Test" && $0.email == "read@test.com" })
        #expect(elapsed < .seconds(1), "Read operations took too long: \(elapsed)")
    }

    // MARK: - Mixed Workload

    @Test("Mixed read/write workload performance")
    func testMixedWorkload() async throws {
        let baseUser = try User(firstName: "Mixed", lastName: "Test", email: "mixed@test.com")

        let startTime = ContinuousClock.now

        // 70% reads, 30% writes
        let results = await withTaskGroup(
            of: (isWrite: Bool, success: Bool).self,
            returning: [(isWrite: Bool, success: Bool)].self
        ) { group in
            for i in 0..<1000 {
                let isWrite = i % 10 < 3 // 30% writes
                group.addTask {
                    if isWrite {
                        // swiftlint:disable:next force_try
                        let modified = try! baseUser.with(firstName: "Modified\(i)")
                        return (true, modified.firstName.starts(with: "Modified"))
                    } else {
                        _ = baseUser.fullName
                        _ = baseUser.email
                        _ = baseUser.isActive
                        return (false, true)
                    }
                }
            }

            var results: [(isWrite: Bool, success: Bool)] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        let writes = results.filter { $0.isWrite }
        let reads = results.filter { !$0.isWrite }

        #expect(writes.count == 300)
        #expect(reads.count == 700)
        #expect(results.allSatisfy { $0.success })
        #expect(elapsed < .seconds(2), "Mixed workload took too long: \(elapsed)")
    }

    // MARK: - Aggregation Performance

    @Test("Concurrent aggregation produces correct results")
    func testConcurrentAggregation() async throws {
        // Create 100 users
        let users = try (0..<100).map { i in
            try User(firstName: "User", lastName: "\(i)", email: "user\(i)@agg.test")
        }

        let startTime = ContinuousClock.now

        // Concurrently count total fullName length across all users
        let totalLength = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            for user in users {
                group.addTask {
                    user.fullName.count
                }
            }

            var total = 0
            for await count in group {
                total += count
            }
            return total
        }

        let elapsed = ContinuousClock.now - startTime

        // Expected: "User 0" to "User 99" - calculate actual expected length
        // "User " = 5 chars + digit length (1 or 2)
        // 0-9: 10 users * (5 + 1) = 60
        // 10-99: 90 users * (5 + 2) = 630
        let expectedTotal = 10 * 6 + 90 * 7  // = 60 + 630 = 690
        #expect(totalLength == expectedTotal)
        #expect(elapsed < .seconds(1), "Aggregation took too long: \(elapsed)")
    }

    // MARK: - Stress Test

    @Test("Extreme concurrent pressure test")
    func testExtremeConcurrentPressure() async throws {
        let startTime = ContinuousClock.now

        // Spawn many tasks that each do multiple operations
        let results = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            for i in 0..<200 {
                group.addTask {
                    var operationCount = 0

                    // Create and modify user (5 operations)
                    // swiftlint:disable:next force_try
                    var user = try! User(firstName: "Stress", lastName: "\(i)", email: "stress\(i)@test.com")
                    for j in 0..<5 {
                        // swiftlint:disable:next force_try
                        user = try! user.with(firstName: "Stress\(j)")
                        operationCount += 1
                    }

                    // Create and modify role
                    // swiftlint:disable:next force_try
                    var role = try! Role(name: "StressRole \(i)", level: .teacher)
                    for _ in 0..<5 {
                        role = role.addPermission(UUID())
                        operationCount += 1
                    }

                    // Create and modify document
                    // swiftlint:disable:next force_try
                    var doc = try! Document(
                        title: "StressDoc \(i)",
                        content: "Content",
                        type: .lesson,
                        ownerID: user.id
                    )
                    for _ in 0..<5 {
                        doc = doc.addCollaborator(UUID())
                        operationCount += 1
                    }

                    return operationCount
                }
            }

            var total = 0
            for await count in group {
                total += count
            }
            return total
        }

        let elapsed = ContinuousClock.now - startTime

        // 200 tasks * 15 operations each = 3000 total operations
        #expect(results == 3000)
        #expect(elapsed < .seconds(2), "Stress test took too long: \(elapsed)")
    }

    // MARK: - School Concurrency Tests

    @Test("1000+ School copy operations complete quickly")
    func testMassiveSchoolCopyOperations() async throws {
        let baseSchool = try School(
            name: "Performance School",
            code: "PERF-001",
            isActive: true,
            address: "123 Test St",
            city: "Test City",
            country: "Test Country"
        )

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: School.self, returning: [School].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var modified = try! baseSchool.with(name: "School\(i)")
                    if i % 2 == 0 {
                        modified = modified.with(isActive: false)
                    }
                    return modified
                }
            }

            var results: [School] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "School operations took too long: \(elapsed)")
    }

    @Test("1000+ School operations with metadata")
    func testMassiveSchoolMetadataOperations() async throws {
        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: School.self, returning: [School].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    try! School(
                        name: "Metadata School \(i)",
                        code: "META-\(i)",
                        isActive: true,
                        metadata: [
                            "index": .integer(i),
                            "active": .bool(i % 2 == 0),
                            "tier": .string("standard")
                        ]
                    )
                }
            }

            var results: [School] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "School metadata operations took too long: \(elapsed)")
    }

    // MARK: - AcademicUnit Concurrency Tests

    @Test("1000+ AcademicUnit operations complete quickly")
    func testMassiveAcademicUnitOperations() async throws {
        let schoolID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: AcademicUnit?.self, returning: [AcademicUnit].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    try? AcademicUnit(
                        displayName: "Unit \(i)",
                        type: AcademicUnitType.allCases[i % AcademicUnitType.allCases.count],
                        schoolID: schoolID,
                        metadata: [
                            "order": .integer(i),
                            "capacity": .integer(30 + (i % 20))
                        ]
                    )
                }
            }

            var results: [AcademicUnit] = []
            results.reserveCapacity(1000)
            for await result in group {
                if let unit = result {
                    results.append(unit)
                }
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "AcademicUnit operations took too long: \(elapsed)")
    }

    @Test("1000+ AcademicUnit hierarchy operations")
    func testMassiveAcademicUnitHierarchyOperations() async throws {
        let schoolID = UUID()
        let parentIDs = (0..<10).map { _ in UUID() }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: AcademicUnit?.self, returning: [AcademicUnit].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    try? AcademicUnit(
                        displayName: "Child Unit \(i)",
                        type: .section,
                        parentUnitID: parentIDs[i % parentIDs.count],
                        schoolID: schoolID
                    )
                }
            }

            var results: [AcademicUnit] = []
            results.reserveCapacity(1000)
            for await result in group {
                if let unit = result {
                    results.append(unit)
                }
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "AcademicUnit hierarchy operations took too long: \(elapsed)")
    }

    // MARK: - Membership Concurrency Tests

    @Test("1000+ Membership operations complete quickly")
    func testMassiveMembershipOperations() async throws {
        let userIDs = (0..<50).map { _ in UUID() }
        let unitIDs = (0..<20).map { _ in UUID() }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Membership.self, returning: [Membership].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    Membership(
                        userID: userIDs[i % userIDs.count],
                        unitID: unitIDs[i % unitIDs.count],
                        role: MembershipRole.allCases[i % MembershipRole.allCases.count],
                        isActive: i % 10 != 0,
                        enrolledAt: Date()
                    )
                }
            }

            var results: [Membership] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "Membership operations took too long: \(elapsed)")
    }

    @Test("1000+ Membership role transitions")
    func testMassiveMembershipRoleTransitions() async throws {
        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: [Membership].self, returning: [[Membership]].self) { group in
            for i in 0..<200 {
                group.addTask {
                    var memberships: [Membership] = []
                    var current = Membership(
                        userID: UUID(),
                        unitID: UUID(),
                        role: .student,
                        isActive: true,
                        enrolledAt: Date()
                    )
                    memberships.append(current)

                    // Transition through roles
                    for role in MembershipRole.allCases {
                        current = Membership(
                            id: current.id,
                            userID: current.userID,
                            unitID: current.unitID,
                            role: role,
                            isActive: true,
                            enrolledAt: current.enrolledAt,
                            createdAt: current.createdAt,
                            updatedAt: Date()
                        )
                        memberships.append(current)
                    }

                    return memberships
                }
            }

            var results: [[Membership]] = []
            for await batch in group {
                results.append(batch)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 200)
        #expect(elapsed < .seconds(2), "Membership role transitions took too long: \(elapsed)")
    }

    // MARK: - Material Concurrency Tests

    @Test("1000+ Material operations complete quickly")
    func testMassiveMaterialOperations() async throws {
        let schoolID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Material?.self, returning: [Material].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    try? Material(
                        title: "Material \(i)",
                        description: "Description for material \(i)",
                        status: MaterialStatus.allCases[i % MaterialStatus.allCases.count],
                        schoolID: schoolID,
                        isPublic: i % 2 == 0
                    )
                }
            }

            var results: [Material] = []
            results.reserveCapacity(1000)
            for await result in group {
                if let material = result {
                    results.append(material)
                }
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "Material operations took too long: \(elapsed)")
    }

    @Test("1000+ Material status transitions")
    func testMassiveMaterialStatusTransitions() async throws {
        let schoolID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: [Material].self, returning: [[Material]].self) { group in
            for i in 0..<200 {
                group.addTask {
                    var materials: [Material] = []

                    // swiftlint:disable:next force_try
                    var current = try! Material(
                        title: "Transition Material \(i)",
                        status: .uploaded,
                        schoolID: schoolID,
                        isPublic: false
                    )
                    materials.append(current)

                    // Transition through statuses: uploaded -> processing -> ready
                    for status in [MaterialStatus.processing, .ready] {
                        // swiftlint:disable:next force_try
                        current = try! Material(
                            id: current.id,
                            title: current.title,
                            status: status,
                            schoolID: current.schoolID,
                            isPublic: current.isPublic,
                            createdAt: current.createdAt,
                            updatedAt: Date()
                        )
                        materials.append(current)
                    }

                    return materials
                }
            }

            var results: [[Material]] = []
            for await batch in group {
                results.append(batch)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 200)
        #expect(elapsed < .seconds(2), "Material status transitions took too long: \(elapsed)")
    }

    // MARK: - DTO Conversion Concurrency Tests

    @Test("1000+ User DTO conversions complete quickly")
    func testMassiveUserDTOConversions() async throws {
        let users = try (0..<1000).map { i in
            try User(firstName: "User", lastName: "\(i)", email: "user\(i)@dto.test")
        }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: (UserDTO, User?).self, returning: [(UserDTO, User?)].self) { group in
            for user in users {
                group.addTask {
                    let dto = user.toDTO()
                    let restored = try? dto.toDomain()
                    return (dto, restored)
                }
            }

            var results: [(UserDTO, User?)] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(results.allSatisfy { $0.1 != nil })
        #expect(elapsed < .seconds(2), "User DTO conversions took too long: \(elapsed)")
    }

    @Test("1000+ School DTO conversions complete quickly")
    func testMassiveSchoolDTOConversions() async throws {
        let schools = try (0..<1000).map { i in
            try School(name: "School \(i)", code: "SCH-\(i)")
        }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: (SchoolDTO, School?).self, returning: [(SchoolDTO, School?)].self) { group in
            for school in schools {
                group.addTask {
                    let dto = school.toDTO()
                    let restored = try? dto.toDomain()
                    return (dto, restored)
                }
            }

            var results: [(SchoolDTO, School?)] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(results.allSatisfy { $0.1 != nil })
        #expect(elapsed < .seconds(2), "School DTO conversions took too long: \(elapsed)")
    }

    @Test("1000+ Membership DTO conversions complete quickly")
    func testMassiveMembershipDTOConversions() async throws {
        let memberships = (0..<1000).map { i in
            Membership(
                userID: UUID(),
                unitID: UUID(),
                role: MembershipRole.allCases[i % MembershipRole.allCases.count],
                isActive: true,
                enrolledAt: Date()
            )
        }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(
            of: (MembershipDTO, Membership?).self,
            returning: [(MembershipDTO, Membership?)].self
        ) { group in
            for membership in memberships {
                group.addTask {
                    let dto = membership.toDTO()
                    let restored = try? dto.toDomain()
                    return (dto, restored)
                }
            }

            var results: [(MembershipDTO, Membership?)] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(results.allSatisfy { $0.1 != nil })
        #expect(elapsed < .seconds(2), "Membership DTO conversions took too long: \(elapsed)")
    }

    // MARK: - Complete Entity Graph Concurrency Tests

    @Test("Concurrent creation of complete school hierarchies")
    func testConcurrentSchoolHierarchyCreation() async throws {
        let startTime = ContinuousClock.now

        let results = await withTaskGroup(
            of: (School, [AcademicUnit], [Membership])?.self,
            returning: [(School, [AcademicUnit], [Membership])].self
        ) { group in
            for i in 0..<100 {
                group.addTask {
                    guard let school = try? School(
                        name: "Hierarchy School \(i)",
                        code: "HIER-\(i)"
                    ) else { return nil }

                    var units: [AcademicUnit] = []
                    // Create 3 grades
                    for g in 1...3 {
                        guard let grade = try? AcademicUnit(
                            displayName: "Grade \(g)",
                            type: .grade,
                            schoolID: school.id
                        ) else { continue }
                        units.append(grade)

                        // Create 2 sections per grade
                        for s in 1...2 {
                            guard let section = try? AcademicUnit(
                                displayName: "Section \(g)-\(s)",
                                type: .section,
                                parentUnitID: grade.id,
                                schoolID: school.id
                            ) else { continue }
                            units.append(section)
                        }
                    }

                    // Create memberships
                    var memberships: [Membership] = []
                    for unit in units {
                        let membership = Membership(
                            userID: UUID(),
                            unitID: unit.id,
                            role: .teacher,
                            isActive: true,
                            enrolledAt: Date()
                        )
                        memberships.append(membership)
                    }

                    return (school, units, memberships)
                }
            }

            var results: [(School, [AcademicUnit], [Membership])] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 100)
        // Each hierarchy: 1 school + 9 units (3 grades + 6 sections) + 9 memberships
        let totalUnits = results.reduce(0) { $0 + $1.1.count }
        #expect(totalUnits == 900) // 100 schools * 9 units
        #expect(elapsed < .seconds(3), "Concurrent hierarchy creation took too long: \(elapsed)")
    }
}

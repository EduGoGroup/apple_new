import Testing
@testable import EduDomain

// MARK: - RoleManager Concurrency Tests

@Suite("RoleManager Concurrency Tests")
struct RoleManagerConcurrencyTests {

    // MARK: - Concurrent Reads

    @Test("Concurrent reads return consistent state")
    func testConcurrentReads_returnConsistentState() async {
        let manager = RoleManager()
        await manager.setRole(.teacher)

        // Perform 100 concurrent reads
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    await manager.hasPermission(.viewMaterials)
                }
            }

            // All reads should return true (teacher has viewMaterials)
            for await result in group {
                #expect(result == true)
            }
        }
    }

    @Test("Concurrent role reads are consistent")
    func testConcurrentRoleReads_areConsistent() async {
        let manager = RoleManager()
        await manager.setRole(.admin)

        // Perform concurrent role reads
        await withTaskGroup(of: SystemRole.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await manager.getCurrentRole()
                }
            }

            for await role in group {
                #expect(role == .admin)
            }
        }
    }

    @Test("Concurrent permission reads are consistent")
    func testConcurrentPermissionReads_areConsistent() async {
        let manager = RoleManager()
        await manager.setRole(.student)

        let expectedPerms = Permission.studentPermissions

        await withTaskGroup(of: Permission.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await manager.getCurrentPermissions()
                }
            }

            for await perms in group {
                #expect(perms == expectedPerms)
            }
        }
    }

    @Test("Detached tasks read consistent permissions")
    func testDetachedTasks_readConsistentPermissions() async {
        let manager = RoleManager()
        await manager.setRole(.teacher)

        let tasks = (0..<50).map { _ in
            Task.detached {
                await manager.hasPermission(.viewMaterials)
            }
        }

        for task in tasks {
            let result = await task.value
            #expect(result == true)
        }
    }

    // MARK: - Concurrent Writes

    @Test("Sequential role changes maintain consistency")
    func testSequentialRoleChanges_maintainConsistency() async {
        let manager = RoleManager()

        // Change roles sequentially and verify each change
        let roles: [SystemRole] = [.student, .teacher, .admin, .guardian, .student]

        for role in roles {
            await manager.setRole(role)
            let currentRole = await manager.getCurrentRole()
            let currentPerms = await manager.getCurrentPermissions()

            #expect(currentRole == role)
            #expect(currentPerms == Permission.defaultPermissions(for: role))
        }
    }

    @Test("Concurrent role changes complete without crashes")
    func testConcurrentRoleChanges_completeWithoutCrashes() async {
        let manager = RoleManager()
        let roles: [SystemRole] = [.student, .teacher, .admin, .guardian]

        // Perform concurrent role changes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                let role = roles[i % roles.count]
                group.addTask {
                    await manager.setRole(role)
                }
            }
        }

        // After all changes, state should be valid
        let finalRole = await manager.getCurrentRole()
        let finalPerms = await manager.getCurrentPermissions()

        // Should be one of the valid roles
        #expect(roles.contains(finalRole))
        // Permissions should match the role
        #expect(finalPerms == Permission.defaultPermissions(for: finalRole))
    }

    // MARK: - Mixed Read/Write

    @Test("Mixed concurrent reads and writes maintain data integrity")
    func testMixedConcurrentReadsWrites_maintainDataIntegrity() async {
        let manager = RoleManager()
        await manager.setRole(.teacher)

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for _ in 0..<5 {
                group.addTask {
                    await manager.setRole(.admin)
                }
                group.addTask {
                    await manager.setRole(.teacher)
                }
            }

            // Readers
            for _ in 0..<20 {
                group.addTask {
                    _ = await manager.getCurrentRole()
                    _ = await manager.getCurrentPermissions()
                    _ = await manager.hasPermission(.viewMaterials)
                }
            }
        }

        // Final state should be consistent
        let finalRole = await manager.getCurrentRole()
        let finalPerms = await manager.getCurrentPermissions()

        #expect(finalPerms == Permission.defaultPermissions(for: finalRole))
    }

    // MARK: - Actor Isolation

    @Test("Actor isolation prevents data races on hasPermission")
    func testActorIsolation_preventsDataRacesOnHasPermission() async {
        let manager = RoleManager()

        // Start with student
        await manager.setRole(.student)

        // Concurrent permission checks and role changes
        await withTaskGroup(of: Void.self) { group in
            // Check permissions concurrently
            for _ in 0..<50 {
                group.addTask {
                    // These should never crash due to actor isolation
                    _ = await manager.hasPermission(.viewMaterials)
                    _ = await manager.hasAllPermissions([.viewMaterials, .takeQuizzes])
                    _ = await manager.hasAnyPermission([.manageUsers, .viewMaterials])
                }
            }

            // Change role concurrently
            for _ in 0..<10 {
                group.addTask {
                    await manager.setRole(.teacher)
                }
            }
        }

        // Final state should be consistent after concurrent access
        let finalRole = await manager.getCurrentRole()
        let finalPerms = await manager.getCurrentPermissions()

        #expect(finalRole == .teacher)
        #expect(finalPerms == Permission.defaultPermissions(for: finalRole))
    }

    @Test("Actor isolation on reset during concurrent access")
    func testActorIsolation_resetDuringConcurrentAccess() async {
        let manager = RoleManager()
        await manager.setRole(.admin)

        await withTaskGroup(of: Void.self) { group in
            // Readers
            for _ in 0..<30 {
                group.addTask {
                    _ = await manager.getCurrentRole()
                    _ = await manager.hasPermission(.manageUsers)
                }
            }

            // Reset in the middle
            group.addTask {
                await manager.reset()
            }
        }

        // After reset, should be back to student
        let finalRole = await manager.getCurrentRole()
        #expect(finalRole == .student)
    }

    // MARK: - Shared Instance

    @Test("Shared instance handles concurrent access")
    func testSharedInstance_handlesConcurrentAccess() async {
        // Using shared instance
        let shared = RoleManager.shared

        // Store original state to restore later
        let originalRole = await shared.getCurrentRole()

        // Concurrent operations on shared instance
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await shared.setRole(.teacher)
                }
                group.addTask {
                    _ = await shared.hasPermission(.viewMaterials)
                }
            }
        }

        // Restore original state
        await shared.setRole(originalRole)

        // Ensure state was restored correctly
        let finalRole = await shared.getCurrentRole()
        let finalPerms = await shared.getCurrentPermissions()

        #expect(finalRole == originalRole)
        #expect(finalPerms == Permission.defaultPermissions(for: originalRole))
    }

    // MARK: - Custom Permissions Concurrency

    @Test("Custom permissions maintain consistency under concurrent access")
    func testCustomPermissions_maintainConsistency() async {
        let manager = RoleManager()

        await withTaskGroup(of: Void.self) { group in
            // Set role with custom permissions
            for _ in 0..<10 {
                group.addTask {
                    await manager.setRole(.student, withAdditionalPermissions: .exportReports)
                }
            }

            // Read custom permissions
            for _ in 0..<20 {
                group.addTask {
                    let custom = await manager.getCustomPermissions()
                    // Should be either empty or .exportReports
                    #expect(custom == [] || custom == .exportReports)
                }
            }
        }
    }
}

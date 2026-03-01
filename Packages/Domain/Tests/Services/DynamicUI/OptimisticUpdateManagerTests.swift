import Foundation
import Testing
@testable import EduDomain
import EduCore
import EduDynamicUI

@Suite("OptimisticUpdateManager Tests")
struct OptimisticUpdateManagerTests {

    @Test("Register optimistic update stores it with pending status")
    func testRegisterOptimisticUpdate() async {
        let manager = OptimisticUpdateManager()

        let updateId = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: [["id": .string("1"), "name": .string("Old School")]],
            optimisticItems: [["id": .string("new"), "name": .string("New School")]],
            fieldValues: ["name": "New School"]
        )

        let isPending = await manager.isPending(id: updateId)
        #expect(isPending == true)

        let count = await manager.pendingCount()
        #expect(count == 1)
    }

    @Test("Confirm update changes status and removes from pending")
    func testConfirmUpdateChangesStatus() async {
        let manager = OptimisticUpdateManager()

        let updateId = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: [],
            optimisticItems: [],
            fieldValues: ["name": "Test"]
        )

        #expect(await manager.isPending(id: updateId) == true)

        await manager.confirmUpdate(id: updateId)

        // After confirmation, the update should be removed from pending
        #expect(await manager.isPending(id: updateId) == false)
        #expect(await manager.pendingCount() == 0)
    }

    @Test("Rollback returns previous items")
    func testRollbackReturnsPreviousItems() async {
        let manager = OptimisticUpdateManager()
        let previousItems: [[String: JSONValue]] = [
            ["id": .string("1"), "name": .string("School A")],
            ["id": .string("2"), "name": .string("School B")]
        ]

        let updateId = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: previousItems,
            optimisticItems: [["id": .string("new"), "name": .string("New")]],
            fieldValues: ["name": "New"]
        )

        let restored = await manager.rollbackUpdate(id: updateId)

        #expect(restored != nil)
        #expect(restored?.count == 2)
        #expect(restored?[0]["name"] == .string("School A"))
        #expect(restored?[1]["name"] == .string("School B"))
        #expect(await manager.pendingCount() == 0)
    }

    @Test("hasPendingUpdates returns true for screen with pending update")
    func testHasPendingUpdatesForScreen() async {
        let manager = OptimisticUpdateManager()

        await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: [],
            optimisticItems: [],
            fieldValues: ["name": "Test"]
        )

        let hasPending = await manager.hasPendingUpdates(forScreen: "schools-list")
        #expect(hasPending == true)

        let hasOther = await manager.hasPendingUpdates(forScreen: "users-list")
        #expect(hasOther == false)
    }

    @Test("Cleanup expired removes timed out updates")
    func testCleanupExpiredRemovesTimedOut() async {
        let manager = OptimisticUpdateManager()

        // Register with a very short timeout (0.1 seconds)
        let updateId = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: [["id": .string("1")]],
            optimisticItems: [],
            fieldValues: ["name": "Test"],
            timeoutSeconds: 0.1
        )

        // Wait for the timeout to elapse
        try? await Task.sleep(for: .milliseconds(200))

        await manager.cleanupExpired()

        #expect(await manager.isPending(id: updateId) == false)
        #expect(await manager.pendingCount() == 0)
    }

    @Test("Multiple updates for different screens coexist")
    func testMultipleUpdatesCoexist() async {
        let manager = OptimisticUpdateManager()

        let id1 = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: [["id": .string("s1")]],
            optimisticItems: [],
            fieldValues: ["name": "School"]
        )

        let id2 = await manager.registerOptimisticUpdate(
            screenKey: "users-list",
            event: .saveExisting,
            previousItems: [["id": .string("u1")]],
            optimisticItems: [],
            fieldValues: ["name": "User"]
        )

        #expect(await manager.pendingCount() == 2)
        #expect(await manager.isPending(id: id1) == true)
        #expect(await manager.isPending(id: id2) == true)
        #expect(await manager.hasPendingUpdates(forScreen: "schools-list") == true)
        #expect(await manager.hasPendingUpdates(forScreen: "users-list") == true)

        // Confirm one, the other should remain
        await manager.confirmUpdate(id: id1)
        #expect(await manager.pendingCount() == 1)
        #expect(await manager.isPending(id: id1) == false)
        #expect(await manager.isPending(id: id2) == true)
    }

    @Test("Status stream emits confirmed event")
    func testStatusStreamEmitsConfirmed() async {
        let manager = OptimisticUpdateManager()
        let stream = await manager.statusStream

        let updateId = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: [],
            optimisticItems: [],
            fieldValues: ["name": "Test"]
        )

        // Confirm in a separate task
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await manager.confirmUpdate(id: updateId)
        }

        // Read first event from stream
        var receivedEvent: OptimisticStatusEvent?
        for await event in stream {
            receivedEvent = event
            break
        }

        #expect(receivedEvent?.updateId == updateId)
        #expect(receivedEvent?.status == .confirmed)
    }

    @Test("Status stream emits rolledBack event with previous items")
    func testStatusStreamEmitsRolledBack() async {
        let manager = OptimisticUpdateManager()
        let stream = await manager.statusStream
        let previousItems: [[String: JSONValue]] = [["id": .string("1")]]

        let updateId = await manager.registerOptimisticUpdate(
            screenKey: "schools-list",
            event: .saveNew,
            previousItems: previousItems,
            optimisticItems: [],
            fieldValues: ["name": "Test"]
        )

        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await manager.rollbackUpdate(id: updateId)
        }

        var receivedEvent: OptimisticStatusEvent?
        for await event in stream {
            receivedEvent = event
            break
        }

        #expect(receivedEvent?.updateId == updateId)
        #expect(receivedEvent?.status == .rolledBack)
        #expect(receivedEvent?.previousItems?.count == 1)
    }
}

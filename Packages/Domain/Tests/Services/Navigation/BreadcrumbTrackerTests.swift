// BreadcrumbTrackerTests.swift
// EduDomainTests

import Testing
import Foundation
@testable import EduDomain

@Suite("BreadcrumbTracker Tests")
struct BreadcrumbTrackerTests {

    // MARK: - Push

    @Test("Push adds entry to trail")
    func testPushAddsEntry() async {
        let tracker = BreadcrumbTracker()

        await tracker.push(screenKey: "schools-list", title: "Schools", icon: "list.bullet", pattern: "list")

        let trail = await tracker.currentTrail()
        #expect(trail.count == 1)
        #expect(trail[0].screenKey == "schools-list")
        #expect(trail[0].title == "Schools")
        #expect(trail[0].icon == "list.bullet")
        #expect(trail[0].pattern == "list")
    }

    @Test("Push duplicate screenKey prunes trail to existing entry")
    func testPushDuplicatePrunes() async {
        let tracker = BreadcrumbTracker()

        await tracker.push(screenKey: "A", title: "Screen A", pattern: "list")
        await tracker.push(screenKey: "B", title: "Screen B", pattern: "detail")
        await tracker.push(screenKey: "A", title: "Screen A", pattern: "list")

        let trail = await tracker.currentTrail()
        #expect(trail.count == 1)
        #expect(trail[0].screenKey == "A")
    }

    @Test("Push multiple unique entries builds correct trail")
    func testPushMultipleEntries() async {
        let tracker = BreadcrumbTracker()

        await tracker.push(screenKey: "A", title: "A", pattern: "dashboard")
        await tracker.push(screenKey: "B", title: "B", pattern: "list")
        await tracker.push(screenKey: "C", title: "C", pattern: "detail")

        let trail = await tracker.currentTrail()
        #expect(trail.count == 3)
        #expect(trail[0].screenKey == "A")
        #expect(trail[1].screenKey == "B")
        #expect(trail[2].screenKey == "C")
    }

    // MARK: - NavigateTo

    @Test("NavigateTo truncates trail after target entry")
    func testNavigateToTruncates() async {
        let tracker = BreadcrumbTracker()

        await tracker.push(screenKey: "A", title: "A", pattern: "dashboard")
        await tracker.push(screenKey: "B", title: "B", pattern: "list")
        await tracker.push(screenKey: "C", title: "C", pattern: "detail")

        let trailBefore = await tracker.currentTrail()
        let entryBId = trailBefore[1].id

        let result = await tracker.navigateTo(entryId: entryBId)

        #expect(result?.screenKey == "B")
        let trail = await tracker.currentTrail()
        #expect(trail.count == 2)
        #expect(trail[0].screenKey == "A")
        #expect(trail[1].screenKey == "B")
    }

    @Test("NavigateTo with unknown entryId returns nil")
    func testNavigateToUnknownReturnsNil() async {
        let tracker = BreadcrumbTracker()
        await tracker.push(screenKey: "A", title: "A", pattern: "list")

        let result = await tracker.navigateTo(entryId: "non-existent-id")

        #expect(result == nil)
        let trail = await tracker.currentTrail()
        #expect(trail.count == 1)
    }

    // MARK: - Pop

    @Test("Pop removes last entry")
    func testPopRemovesLast() async {
        let tracker = BreadcrumbTracker()

        await tracker.push(screenKey: "A", title: "A", pattern: "dashboard")
        await tracker.push(screenKey: "B", title: "B", pattern: "list")

        await tracker.pop()

        let trail = await tracker.currentTrail()
        #expect(trail.count == 1)
        #expect(trail[0].screenKey == "A")
    }

    @Test("Pop on empty trail does nothing")
    func testPopOnEmptyTrail() async {
        let tracker = BreadcrumbTracker()

        await tracker.pop()

        let trail = await tracker.currentTrail()
        #expect(trail.isEmpty)
    }

    // MARK: - Clear

    @Test("Clear empties the trail")
    func testClearEmptiesTrail() async {
        let tracker = BreadcrumbTracker()

        await tracker.push(screenKey: "A", title: "A", pattern: "dashboard")
        await tracker.push(screenKey: "B", title: "B", pattern: "list")

        await tracker.clear()

        let trail = await tracker.currentTrail()
        #expect(trail.isEmpty)
    }

    // MARK: - Max Depth

    @Test("Max depth is respected — oldest entries are pruned")
    func testMaxDepthRespected() async {
        let tracker = BreadcrumbTracker()

        // Push 8 unique entries; max depth is 7
        for i in 1...8 {
            await tracker.push(screenKey: "screen-\(i)", title: "Screen \(i)", pattern: "list")
        }

        let trail = await tracker.currentTrail()
        #expect(trail.count == 7)
        // First entry should be screen-2 (screen-1 was pruned)
        #expect(trail[0].screenKey == "screen-2")
        #expect(trail[6].screenKey == "screen-8")
    }

    // MARK: - AsyncStream

    @Test("Trail stream emits on push")
    func testStreamEmitsOnChanges() async {
        let tracker = BreadcrumbTracker()

        // Capture the stream reference while on the actor's executor
        let stream = await tracker.trailStream

        // Start consuming the stream in a task
        let expectation = Task<[BreadcrumbTracker.BreadcrumbEntry], Never> {
            for await trail in stream {
                return trail
            }
            return []
        }

        // Small delay to let the stream consumer start
        try? await Task.sleep(for: .milliseconds(50))

        await tracker.push(screenKey: "A", title: "Screen A", icon: "house", pattern: "dashboard")

        let emitted = await expectation.value
        #expect(emitted.count == 1)
        #expect(emitted[0].screenKey == "A")
        #expect(emitted[0].title == "Screen A")
        #expect(emitted[0].icon == "house")
    }

    // MARK: - BreadcrumbEntry

    @Test("BreadcrumbEntry conforms to Hashable")
    func testBreadcrumbEntryHashable() async {
        let entry1 = BreadcrumbTracker.BreadcrumbEntry(
            id: "same-id",
            screenKey: "A",
            title: "A",
            pattern: "list"
        )
        let entry2 = BreadcrumbTracker.BreadcrumbEntry(
            id: "same-id",
            screenKey: "A",
            title: "A",
            pattern: "list"
        )
        #expect(entry1 == entry2)
        #expect(entry1.hashValue == entry2.hashValue)
    }

    @Test("BreadcrumbEntry id is auto-generated when not specified")
    func testBreadcrumbEntryAutoId() async {
        let entry = BreadcrumbTracker.BreadcrumbEntry(
            screenKey: "A",
            title: "A",
            pattern: "list"
        )
        #expect(!entry.id.isEmpty)
    }
}

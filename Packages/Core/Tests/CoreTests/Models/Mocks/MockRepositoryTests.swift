//
// MockRepositoryTests.swift
// ModelsTests
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
import Testing
@testable import EduModels

// MARK: - MockUserRepository Tests

@Suite("MockUserRepository Tests")
struct MockUserRepositoryTests {

    // MARK: - Basic Operations

    @Test("get returns nil for non-existent user")
    func getReturnsNilForNonExistent() async throws {
        let mock = MockUserRepository()
        let result = try await mock.get(id: UUID())

        #expect(result == nil)
        #expect(await mock.getCallCount == 1)
    }

    @Test("save stores user and can be retrieved")
    func saveAndRetrieve() async throws {
        let mock = MockUserRepository()
        let user = try User(firstName: "John", lastName: "Doe", email: "john@example.com")

        try await mock.save(user)
        let retrieved = try await mock.get(id: user.id)

        #expect(retrieved == user)
        #expect(await mock.saveCallCount == 1)
        #expect(await mock.lastSavedUser == user)
    }

    @Test("delete removes user from storage")
    func deleteRemovesUser() async throws {
        let mock = MockUserRepository()
        let user = try User(firstName: "Jane", lastName: "Doe", email: "jane@example.com")

        try await mock.save(user)
        #expect(await mock.contains(id: user.id))

        try await mock.delete(id: user.id)
        #expect(await !mock.contains(id: user.id))
        #expect(await mock.deleteCallCount == 1)
        #expect(await mock.lastDeleteID == user.id)
    }

    @Test("list returns all stored users")
    func listReturnsAllUsers() async throws {
        let mock = MockUserRepository()
        let user1 = try User(firstName: "User", lastName: "One", email: "one@example.com")
        let user2 = try User(firstName: "User", lastName: "Two", email: "two@example.com")

        try await mock.save(user1)
        try await mock.save(user2)

        let users = try await mock.list()

        #expect(users.count == 2)
        #expect(await mock.listCallCount == 1)
    }

    // MARK: - Stubbing

    @Test("stubbedUser overrides storage lookup")
    func stubbedUserOverridesStorage() async throws {
        let mock = MockUserRepository()
        let storedUser = try User(firstName: "Stored", lastName: "User", email: "stored@example.com")
        let stubbedUser = try User(firstName: "Stubbed", lastName: "User", email: "stubbed@example.com")

        try await mock.save(storedUser)
        await mock.setStubbedUser(stubbedUser)

        let result = try await mock.get(id: storedUser.id)

        #expect(result == stubbedUser)
    }

    @Test("stubbedError throws on any operation")
    func stubbedErrorThrows() async throws {
        let mock = MockUserRepository()
        await mock.setStubbedError(TestError.simulated)

        await #expect(throws: TestError.self) {
            _ = try await mock.get(id: UUID())
        }

        await #expect(throws: TestError.self) {
            let user = try User(firstName: "Test", lastName: "User", email: "test@example.com")
            try await mock.save(user)
        }
    }

    // MARK: - Reset

    @Test("reset clears all state")
    func resetClearsState() async throws {
        let mock = MockUserRepository()
        let user = try User(firstName: "Test", lastName: "User", email: "test@example.com")

        try await mock.save(user)
        _ = try await mock.get(id: user.id)
        _ = try await mock.list()

        await mock.reset()

        #expect(await mock.count == 0)
        #expect(await mock.getCallCount == 0)
        #expect(await mock.saveCallCount == 0)
        #expect(await mock.listCallCount == 0)
    }

    // MARK: - Preload

    @Test("init with users preloads storage")
    func initWithUsersPreloads() async throws {
        let user1 = try User(firstName: "User", lastName: "One", email: "one@example.com")
        let user2 = try User(firstName: "User", lastName: "Two", email: "two@example.com")

        let mock = MockUserRepository(users: [user1, user2])

        #expect(await mock.count == 2)
        #expect(await mock.contains(id: user1.id))
        #expect(await mock.contains(id: user2.id))
    }
}

// MARK: - MockDocumentRepository Tests

@Suite("MockDocumentRepository Tests")
struct MockDocumentRepositoryTests {

    private let ownerID = UUID()

    // MARK: - Basic Operations

    @Test("get returns nil for non-existent document")
    func getReturnsNilForNonExistent() async throws {
        let mock = MockDocumentRepository()
        let result = try await mock.get(id: UUID())

        #expect(result == nil)
        #expect(await mock.getCallCount == 1)
    }

    @Test("save stores document and can be retrieved")
    func saveAndRetrieve() async throws {
        let mock = MockDocumentRepository()
        let doc = try Document(
            title: "Test Document",
            content: "Some content",
            type: .lesson,
            ownerID: ownerID
        )

        try await mock.save(doc)
        let retrieved = try await mock.get(id: doc.id)

        #expect(retrieved == doc)
        #expect(await mock.saveCallCount == 1)
        #expect(await mock.lastSavedDocument == doc)
    }

    @Test("delete removes document from storage")
    func deleteRemovesDocument() async throws {
        let mock = MockDocumentRepository()
        let doc = try Document(
            title: "To Delete",
            content: "Content",
            type: .assignment,
            ownerID: ownerID
        )

        try await mock.save(doc)
        #expect(await mock.contains(id: doc.id))

        try await mock.delete(id: doc.id)
        #expect(await !mock.contains(id: doc.id))
        #expect(await mock.deleteCallCount == 1)
        #expect(await mock.lastDeleteID == doc.id)
    }

    // MARK: - Search

    @Test("search finds documents by title")
    func searchFindsByTitle() async throws {
        let mock = MockDocumentRepository()
        let doc1 = try Document(title: "Swift Programming", content: "Basics", type: .lesson, ownerID: ownerID)
        let doc2 = try Document(title: "Python Programming", content: "Basics", type: .lesson, ownerID: ownerID)
        let doc3 = try Document(title: "Math Quiz", content: "Questions", type: .quiz, ownerID: ownerID)

        try await mock.save(doc1)
        try await mock.save(doc2)
        try await mock.save(doc3)

        let results = try await mock.search(query: "Programming")

        #expect(results.count == 2)
        #expect(await mock.searchCallCount == 1)
        #expect(await mock.lastSearchQuery == "Programming")
    }

    @Test("search finds documents by content")
    func searchFindsByContent() async throws {
        let mock = MockDocumentRepository()
        let doc = try Document(
            title: "Lesson 1",
            content: "Introduction to algorithms",
            type: .lesson,
            ownerID: ownerID
        )

        try await mock.save(doc)

        let results = try await mock.search(query: "algorithms")

        #expect(results.count == 1)
        #expect(results.first == doc)
    }

    @Test("stubbedSearchResults overrides default search")
    func stubbedSearchResultsOverrides() async throws {
        let mock = MockDocumentRepository()
        let storedDoc = try Document(title: "Stored", content: "Content", type: .lesson, ownerID: ownerID)
        let stubbedDoc = try Document(title: "Stubbed", content: "Content", type: .quiz, ownerID: ownerID)

        try await mock.save(storedDoc)
        await mock.setStubbedSearchResults([stubbedDoc])

        let results = try await mock.search(query: "anything")

        #expect(results.count == 1)
        #expect(results.first == stubbedDoc)
    }

    // MARK: - Filtering Helpers

    @Test("documents filtered by type")
    func filterByType() async throws {
        let mock = MockDocumentRepository()
        let lesson = try Document(title: "Lesson", content: "C", type: .lesson, ownerID: ownerID)
        let quiz = try Document(title: "Quiz", content: "C", type: .quiz, ownerID: ownerID)

        try await mock.save(lesson)
        try await mock.save(quiz)

        let lessons = await mock.documents(ofType: .lesson)
        let quizzes = await mock.documents(ofType: .quiz)

        #expect(lessons.count == 1)
        #expect(quizzes.count == 1)
    }

    @Test("documents filtered by owner")
    func filterByOwner() async throws {
        let mock = MockDocumentRepository()
        let owner1 = UUID()
        let owner2 = UUID()

        let doc1 = try Document(title: "Doc 1", content: "C", type: .lesson, ownerID: owner1)
        let doc2 = try Document(title: "Doc 2", content: "C", type: .lesson, ownerID: owner2)

        try await mock.save(doc1)
        try await mock.save(doc2)

        let owner1Docs = await mock.documents(ownedBy: owner1)

        #expect(owner1Docs.count == 1)
        #expect(owner1Docs.first?.ownerID == owner1)
    }

    // MARK: - Error Handling

    @Test("stubbedError throws on any operation")
    func stubbedErrorThrows() async throws {
        let mock = MockDocumentRepository()
        await mock.setStubbedError(TestError.simulated)

        await #expect(throws: TestError.self) {
            _ = try await mock.get(id: UUID())
        }

        await #expect(throws: TestError.self) {
            _ = try await mock.search(query: "test")
        }
    }

    // MARK: - Reset

    @Test("reset clears all state")
    func resetClearsState() async throws {
        let mock = MockDocumentRepository()
        let doc = try Document(title: "Test", content: "C", type: .lesson, ownerID: ownerID)

        try await mock.save(doc)
        _ = try await mock.get(id: doc.id)
        _ = try await mock.search(query: "test")

        await mock.reset()

        #expect(await mock.count == 0)
        #expect(await mock.getCallCount == 0)
        #expect(await mock.saveCallCount == 0)
        #expect(await mock.searchCallCount == 0)
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case simulated
}

// MARK: - Actor Extensions for Testing

extension MockUserRepository {
    func setStubbedUser(_ user: User?) async {
        self.stubbedUser = user
    }

    func setStubbedError(_ error: Error?) async {
        self.stubbedError = error
    }
}

extension MockDocumentRepository {
    func setStubbedSearchResults(_ results: [Document]?) async {
        self.stubbedSearchResults = results
    }

    func setStubbedError(_ error: Error?) async {
        self.stubbedError = error
    }
}

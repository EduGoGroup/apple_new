// NetworkObserverTests.swift
// EduInfrastructureTests

import Testing
import Foundation
@testable import EduNetwork

@Suite("NetworkObserver Tests")
struct NetworkObserverTests {

    @Test("Initial status is unavailable")
    func initialStatus() async {
        let observer = NetworkObserver()
        let status = await observer.status
        #expect(status == .unavailable)
    }

    @Test("Initial isOnline is false")
    func initialIsOnline() async {
        let observer = NetworkObserver()
        let isOnline = await observer.isOnline
        #expect(isOnline == false)
    }

    @Test("Can start and stop without crash")
    func startStop() async {
        let observer = NetworkObserver()
        await observer.start()
        // Dar tiempo al monitor para inicializar
        try? await Task.sleep(for: .milliseconds(100))
        await observer.stop()
    }

    @Test("Multiple start calls are safe")
    func multipleStarts() async {
        let observer = NetworkObserver()
        await observer.start()
        await observer.start() // No debería crear un segundo monitor
        await observer.stop()
    }

    @Test("StatusStream is accessible")
    func statusStreamAccessible() async {
        let observer = NetworkObserver()
        let _ = await observer.statusStream
        // No crash = éxito
    }
}

@Suite("NetworkStatus Tests")
struct NetworkStatusTests {

    @Test("NetworkStatus equality")
    func equality() {
        #expect(NetworkStatus.available == NetworkStatus.available)
        #expect(NetworkStatus.unavailable == NetworkStatus.unavailable)
        #expect(NetworkStatus.losing == NetworkStatus.losing)
        #expect(NetworkStatus.available != NetworkStatus.unavailable)
    }
}

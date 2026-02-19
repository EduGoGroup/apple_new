// MARK: - AccessibilityAnnouncements.swift
// EduAccessibility - VoiceOver Infrastructure
//
// Sistema de announcements para VoiceOver con queue, prioridades y throttling.
// Proporciona una API unificada para iOS y macOS.

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Announcement Priority

/// Niveles de prioridad para announcements de VoiceOver.
///
/// - `high`: Announcements críticos que bypasean throttling (errores, alertas)
/// - `medium`: Announcements importantes con throttling normal (cambios de estado)
/// - `low`: Announcements informativos que pueden ser descartados si hay cola
public enum AnnouncementPriority: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    public static func < (lhs: AnnouncementPriority, rhs: AnnouncementPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Announcement Item

/// Representa un announcement individual en la cola.
struct AnnouncementItem: Sendable {
    let message: String
    let priority: AnnouncementPriority
    let timestamp: Date
    let id: UUID

    init(message: String, priority: AnnouncementPriority) {
        self.message = message
        self.priority = priority
        self.timestamp = Date()
        self.id = UUID()
    }
}

// MARK: - Accessibility Announcements

/// Sistema centralizado para announcements de VoiceOver.
///
/// Proporciona:
/// - Queue con prioridades para evitar saturar VoiceOver
/// - Throttling automático (configurable)
/// - API unificada para iOS y macOS
/// - Thread-safety mediante actor isolation
///
/// ## Ejemplo de uso
/// ```swift
/// // Announcement de alta prioridad (errores)
/// AccessibilityAnnouncements.announce("Error: Invalid email", priority: .high)
///
/// // Announcement de prioridad media (cambios de estado)
/// AccessibilityAnnouncements.announce("Loading complete", priority: .medium)
///
/// // Announcement de baja prioridad (información)
/// AccessibilityAnnouncements.announce("5 items in list", priority: .low)
/// ```
@MainActor
public final class AccessibilityAnnouncements: Sendable {

    // MARK: - Singleton

    /// Instancia compartida del sistema de announcements.
    public static let shared = AccessibilityAnnouncements()

    // MARK: - Configuration

    /// Intervalo mínimo entre announcements de prioridad media/baja (en segundos).
    public static var throttleInterval: TimeInterval = 1.0

    /// Máximo número de items en la cola antes de descartar los de baja prioridad.
    public static var maxQueueSize: Int = 10

    // MARK: - Private State

    private var queue: [AnnouncementItem] = []
    private var lastAnnouncementTime: Date?
    private var isProcessing = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Anuncia un mensaje a VoiceOver con la prioridad especificada.
    ///
    /// - Parameters:
    ///   - message: El mensaje a anunciar.
    ///   - priority: La prioridad del announcement (default: `.medium`).
    ///
    /// ## Comportamiento según prioridad
    /// - `.high`: Se anuncia inmediatamente, bypasea throttling
    /// - `.medium`: Respeta throttling (1 segundo entre announcements)
    /// - `.low`: Puede ser descartado si la cola está llena
    public static func announce(_ message: String, priority: AnnouncementPriority = .medium) {
        Task { @MainActor in
            shared.enqueue(message: message, priority: priority)
        }
    }

    /// Anuncia un mensaje de progreso (ej: "50 percent complete").
    ///
    /// Solo anuncia en milestones (25%, 50%, 75%, 100%) para no saturar.
    ///
    /// - Parameters:
    ///   - progress: Valor de progreso entre 0.0 y 1.0.
    ///   - label: Label descriptivo opcional (default: "Progress").
    public static func announceProgressMilestone(_ progress: Double, label: String = "Progress") {
        let percentage = Int(progress * 100)

        // Solo anunciar en milestones
        guard percentage % 25 == 0 && percentage > 0 else { return }

        announce("\(label): \(percentage) percent complete", priority: .medium)
    }

    /// Anuncia un error con prioridad alta.
    ///
    /// - Parameter message: El mensaje de error.
    public static func announceError(_ message: String) {
        announce("Error: \(message)", priority: .high)
    }

    /// Anuncia un cambio de estado (loading, loaded, etc).
    ///
    /// - Parameters:
    ///   - state: El nuevo estado.
    ///   - context: Contexto opcional (ej: nombre del componente).
    public static func announceStateChange(_ state: String, context: String? = nil) {
        let message = context.map { "\($0): \(state)" } ?? state
        announce(message, priority: .medium)
    }

    /// Limpia la cola de announcements pendientes.
    public static func clearQueue() {
        Task { @MainActor in
            shared.queue.removeAll()
        }
    }

    // MARK: - Private Methods

    private func enqueue(message: String, priority: AnnouncementPriority) {
        let item = AnnouncementItem(message: message, priority: priority)

        // High priority: anunciar inmediatamente
        if priority == .high {
            postAnnouncement(item)
            return
        }

        // Verificar tamaño de cola
        if queue.count >= Self.maxQueueSize {
            // Remover items de baja prioridad
            queue.removeAll { $0.priority == .low }

            // Si aún está llena y el nuevo item es low, descartarlo
            if queue.count >= Self.maxQueueSize && priority == .low {
                return
            }
        }

        // Agregar a la cola ordenada por prioridad
        queue.append(item)
        queue.sort { $0.priority > $1.priority }

        // Procesar cola si no está en proceso
        if !isProcessing {
            processQueue()
        }
    }

    private func processQueue() {
        guard !queue.isEmpty else {
            isProcessing = false
            return
        }

        isProcessing = true

        // Verificar throttling
        if let lastTime = lastAnnouncementTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < Self.throttleInterval {
                // Esperar el tiempo restante
                let delay = Self.throttleInterval - elapsed
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    self.processQueue()
                }
                return
            }
        }

        // Tomar el siguiente item (ya ordenado por prioridad)
        let item = queue.removeFirst()
        postAnnouncement(item)

        // Continuar procesando
        if !queue.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Self.throttleInterval))
                self.processQueue()
            }
        } else {
            isProcessing = false
        }
    }

    private func postAnnouncement(_ item: AnnouncementItem) {
        lastAnnouncementTime = Date()

        #if canImport(UIKit) && !os(watchOS)
        UIAccessibility.post(notification: .announcement, argument: item.message)
        #elseif canImport(AppKit)
        // macOS: Usar NSAccessibility
        if let window = NSApplication.shared.keyWindow {
            NSAccessibility.post(element: window, notification: .announcementRequested, userInfo: [
                .announcement: item.message,
                .priority: NSAccessibilityPriorityLevel.high.rawValue
            ])
        }
        #endif
    }
}

// MARK: - View Extension

public extension View {
    /// Anuncia un mensaje cuando un valor cambia.
    ///
    /// - Parameters:
    ///   - value: El valor a observar.
    ///   - message: Closure que genera el mensaje basado en el nuevo valor.
    ///   - priority: Prioridad del announcement.
    ///
    /// ## Ejemplo
    /// ```swift
    /// TextField("Email", text: $email)
    ///     .announceOnChange(of: validationError) { error in
    ///         error.map { "Validation error: \($0)" }
    ///     }
    /// ```
    func announceOnChange<V: Equatable>(
        of value: V,
        priority: AnnouncementPriority = .medium,
        message: @escaping (V) -> String?
    ) -> some View {
        self.onChange(of: value) { _, newValue in
            if let announcement = message(newValue) {
                AccessibilityAnnouncements.announce(announcement, priority: priority)
            }
        }
    }

    /// Anuncia un mensaje cuando la vista aparece.
    ///
    /// - Parameters:
    ///   - message: El mensaje a anunciar.
    ///   - priority: Prioridad del announcement.
    func announceOnAppear(_ message: String, priority: AnnouncementPriority = .medium) -> some View {
        self.onAppear {
            AccessibilityAnnouncements.announce(message, priority: priority)
        }
    }

    /// Anuncia un mensaje cuando la vista desaparece.
    ///
    /// - Parameters:
    ///   - message: El mensaje a anunciar.
    ///   - priority: Prioridad del announcement.
    func announceOnDisappear(_ message: String, priority: AnnouncementPriority = .low) -> some View {
        self.onDisappear {
            AccessibilityAnnouncements.announce(message, priority: priority)
        }
    }
}

// NetworkStatus.swift
// EduNetwork
//
// Estado de conectividad de red.

import Foundation

/// Estado actual de la conexión de red.
public enum NetworkStatus: Sendable, Equatable {
    /// Red disponible y funcional.
    case available
    /// Sin conexión de red.
    case unavailable
    /// Conexión degradándose o a punto de perderse.
    case losing
}

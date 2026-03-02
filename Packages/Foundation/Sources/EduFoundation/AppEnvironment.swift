//
// AppEnvironment.swift
// EduFoundation
//
// Created by EduGo Team on 20/02/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Entorno de ejecucion de la aplicacion.
///
/// Determina la configuracion de APIs, logging y comportamiento general.
/// Se detecta automaticamente basado en variables de entorno.
///
/// ## Deteccion automatica:
/// - **Default**: `.staging` (Azure APIs) - para desarrollo normal
/// - **Override**: Variable de entorno `EDUGO_ENVIRONMENT`
///
/// ## Variable de entorno:
/// ```
/// EDUGO_ENVIRONMENT=development  // para localhost
/// EDUGO_ENVIRONMENT=staging      // para Azure (default)
/// EDUGO_ENVIRONMENT=production   // para producción
/// ```
///
/// ## Uso en Xcode:
/// Edit Scheme → Run → Arguments → Environment Variables
/// - Key: `EDUGO_ENVIRONMENT`
/// - Value: `development` (para localhost) o `staging` (para Azure)
public enum AppEnvironment: String, Sendable, CaseIterable {
    case development
    case staging
    case production

    /// Detecta automaticamente el entorno de ejecucion.
    ///
    /// Prioridad:
    /// 1. Variable de entorno `EDUGO_ENVIRONMENT`
    /// 2. Default: `.staging` (Azure APIs) - para desarrollo normal
    ///
    /// **Nota**: Por defecto apunta a staging (Azure) para facilitar el desarrollo.
    /// Si necesitas localhost, establece `EDUGO_ENVIRONMENT=development`
    public static func detect() -> AppEnvironment {
        if let envString = ProcessInfo.processInfo.environment["EDUGO_ENVIRONMENT"],
           let env = AppEnvironment(rawValue: envString.lowercased()) {
            return env
        }

        // Default a staging (Azure) para facilitar desarrollo
        // Si necesitas localhost: EDUGO_ENVIRONMENT=development
        return .staging
    }
}

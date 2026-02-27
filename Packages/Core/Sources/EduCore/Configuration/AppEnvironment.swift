//
// AppEnvironment.swift
// EduCore
//
// Created by EduGo Team on 20/02/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Entorno de ejecucion de la aplicacion.
///
/// Determina la configuracion de APIs, logging y comportamiento general.
/// Se detecta automaticamente basado en flags de compilacion y variables
/// de entorno, pero puede ser proporcionado explicitamente.
///
/// ## Deteccion automatica:
/// - **DEBUG build**: `.development`
/// - **RELEASE build**: lee `EDUGO_ENVIRONMENT`, default `.production`
///
/// ## Variable de entorno:
/// ```
/// EDUGO_ENVIRONMENT=staging  // development, staging, production
/// ```
///
/// ## Uso en Xcode:
/// Edit Scheme → Run → Arguments → Environment Variables
/// - Key: `EDUGO_ENVIRONMENT`
/// - Value: `staging`
public enum AppEnvironment: String, Sendable, CaseIterable {
    case development
    case staging
    case production

    /// Detecta automaticamente el entorno de ejecucion.
    ///
    /// Prioridad:
    /// 1. Variable de entorno `EDUGO_ENVIRONMENT`
    /// 2. Flag de compilacion (`DEBUG` → development, else → production)
    public static func detect() -> AppEnvironment {
        if let envString = ProcessInfo.processInfo.environment["EDUGO_ENVIRONMENT"],
           let env = AppEnvironment(rawValue: envString.lowercased()) {
            return env
        }

        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

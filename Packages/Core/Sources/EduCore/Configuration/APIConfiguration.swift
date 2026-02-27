//
// APIConfiguration.swift
// EduCore
//
// Created by EduGo Team on 20/02/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Configuracion de endpoints de API por entorno.
///
/// Proporciona URLs base para las APIs de EduGo (admin y mobile)
/// con presets por entorno y soporte para override via variables de entorno.
///
/// ## Uso basico:
/// ```swift
/// let config = APIConfiguration.forEnvironment(.staging)
/// // config.adminBaseURL  → "https://edugo-api-admin.wittyhill-..."
/// // config.mobileBaseURL → "https://edugo-api-mobile.wittyhill-..."
/// ```
///
/// ## Override via variables de entorno:
/// ```
/// EDUGO_ADMIN_API_URL=https://custom-admin.example.com
/// EDUGO_MOBILE_API_URL=https://custom-mobile.example.com
/// EDUGO_API_TIMEOUT=45
/// ```
///
/// ## Uso en Xcode:
/// Edit Scheme → Run → Arguments → Environment Variables
public struct APIConfiguration: Sendable {

    // MARK: - Environment Variable Keys

    /// Claves de variables de entorno soportadas.
    public enum Key: String, CaseIterable {
        case adminURL = "EDUGO_ADMIN_API_URL"
        case mobileURL = "EDUGO_MOBILE_API_URL"
        case timeout = "EDUGO_API_TIMEOUT"
    }

    // MARK: - Properties

    /// URL base de la API de administracion.
    public let adminBaseURL: String

    /// URL base de la API mobile.
    public let mobileBaseURL: String

    /// Timeout para requests HTTP en segundos.
    public let timeout: TimeInterval

    /// Entorno asociado a esta configuracion.
    public let environment: AppEnvironment

    // MARK: - Initialization

    public init(
        adminBaseURL: String,
        mobileBaseURL: String,
        timeout: TimeInterval = 60,
        environment: AppEnvironment = .detect()
    ) {
        self.adminBaseURL = adminBaseURL
        self.mobileBaseURL = mobileBaseURL
        self.timeout = timeout
        self.environment = environment
    }

    // MARK: - Factory

    /// Crea la configuracion apropiada para un entorno.
    ///
    /// Las variables de entorno tienen prioridad sobre los presets.
    ///
    /// - Parameter environment: Entorno objetivo
    /// - Returns: Configuracion con URLs correctas
    public static func forEnvironment(_ environment: AppEnvironment) -> APIConfiguration {
        let preset = preset(for: environment)
        let processInfo = ProcessInfo.processInfo

        let adminURL = processInfo.environment[Key.adminURL.rawValue]
            ?? preset.adminBaseURL
        let mobileURL = processInfo.environment[Key.mobileURL.rawValue]
            ?? preset.mobileBaseURL
        let timeout = processInfo.environment[Key.timeout.rawValue]
            .flatMap { TimeInterval($0) }
            ?? preset.timeout

        return APIConfiguration(
            adminBaseURL: adminURL,
            mobileBaseURL: mobileURL,
            timeout: timeout,
            environment: environment
        )
    }

    // MARK: - Presets

    private static func preset(for environment: AppEnvironment) -> APIConfiguration {
        switch environment {
        case .development:
            return .development
        case .staging:
            return .staging
        case .production:
            return .production
        }
    }

    /// Desarrollo local: localhost.
    public static let development = APIConfiguration(
        adminBaseURL: "http://localhost:8081",
        mobileBaseURL: "http://localhost:9091",
        timeout: 30,
        environment: .development
    )

    /// Staging: Azure Container Apps.
    public static let staging = APIConfiguration(
        adminBaseURL: "https://edugo-api-admin.wittyhill-f6d656fb.eastus.azurecontainerapps.io",
        mobileBaseURL: "https://edugo-api-mobile.wittyhill-f6d656fb.eastus.azurecontainerapps.io",
        timeout: 60,
        environment: .staging
    )

    /// Produccion: URLs de produccion.
    public static let production = APIConfiguration(
        adminBaseURL: "https://api.edugo.com",
        mobileBaseURL: "https://api-mobile.edugo.com",
        timeout: 60,
        environment: .production
    )
}

// MARK: - CustomStringConvertible

extension APIConfiguration: CustomStringConvertible {
    public var description: String {
        "APIConfiguration(env: \(environment), admin: \(adminBaseURL), mobile: \(mobileBaseURL), timeout: \(timeout)s)"
    }
}

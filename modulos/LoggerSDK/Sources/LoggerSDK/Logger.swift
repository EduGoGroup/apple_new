import Foundation
import OSLog

/// Logger - Centralized logging module
///
/// Provides unified logging capabilities with structured logging support.
/// Configure the subsystem before first use via `Logger.configure(subsystem:)`.
///
/// ## Usage
/// ```swift
/// // Configure at app launch
/// Logger.configure(subsystem: "com.myapp.ios")
///
/// // Use
/// await Logger.shared.info("App started")
/// ```
public actor Logger {
    public static let shared = Logger()

    private var osLogger: os.Logger

    private init() {
        self.osLogger = os.Logger(subsystem: "com.app.default", category: "default")
    }

    /// Configure the logger subsystem. Call once at app startup.
    public func configure(subsystem: String) {
        self.osLogger = os.Logger(subsystem: subsystem, category: "default")
    }

    /// Log a message at the info level
    public func info(_ message: String) {
        osLogger.info("\(message)")
    }

    /// Log a message at the error level
    public func error(_ message: String) {
        osLogger.error("\(message)")
    }

    /// Log a message at the debug level
    public func debug(_ message: String) {
        osLogger.debug("\(message)")
    }
}

import Foundation
import OSLog

/// Logger - Centralized logging module
///
/// Provides unified logging capabilities with structured logging support.
/// TIER-1 Core module.
public actor Logger {
    public static let shared = Logger()

    private let osLogger: os.Logger

    private init() {
        self.osLogger = os.Logger(subsystem: "com.edugo.apple", category: "default")
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

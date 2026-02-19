import Foundation
@testable import LoggerSDK

/// Categorías de test para usar en lugar de StandardLogCategory (que es EduGo-specific).
enum TestLogCategory: String, LogCategory {
    case logger = "com.test.logger.system"
    case network = "com.test.network"
    case database = "com.test.database"
    case auth = "com.test.auth"
    case performance = "com.test.performance"
}

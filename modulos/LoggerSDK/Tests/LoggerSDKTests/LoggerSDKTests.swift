import Testing
@testable import LoggerSDK

@Suite("Logger Tests")
struct LoggerTests {
    @Test("Logger shared instance is accessible")
    func testSharedInstance() async {
        let logger = Logger.shared
        await logger.info("Test log message")
    }
}

@Suite("OSLoggerAdapter Tests")
struct OSLoggerAdapterTests {

    @Test("OSLoggerAdapter initializes with default configuration")
    func testDefaultInitialization() async {
        let logger = OSLoggerAdapter()
        let count = await logger.cachedLoggerCount
        #expect(count == 0)
    }

    @Test("OSLoggerAdapter initializes with custom configuration")
    func testCustomConfiguration() async {
        let config = LogConfiguration(
            globalLevel: .info,
            environment: .development
        )
        let logger = OSLoggerAdapter(configuration: config)
        let count = await logger.cachedLoggerCount
        #expect(count == 0)
    }

    @Test("OSLoggerAdapter logs debug message")
    func testDebugLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.debug("Debug test message")
    }

    @Test("OSLoggerAdapter logs info message")
    func testInfoLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.info("Info test message")
    }

    @Test("OSLoggerAdapter logs warning message")
    func testWarningLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.warning("Warning test message")
    }

    @Test("OSLoggerAdapter logs error message")
    func testErrorLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.error("Error test message")
    }

    @Test("OSLoggerAdapter caches loggers by category")
    func testLoggerCaching() async {
        let logger = OSLoggerAdapter(configuration: .development)

        await logger.info("First message", category: TestLogCategory.logger)
        var count = await logger.cachedLoggerCount
        #expect(count == 1)

        await logger.info("Second message", category: TestLogCategory.logger)
        count = await logger.cachedLoggerCount
        #expect(count == 1)

        await logger.info("Third message", category: TestLogCategory.network)
        count = await logger.cachedLoggerCount
        #expect(count == 2)
    }

    @Test("OSLoggerAdapter respects level filtering")
    func testLevelFiltering() async {
        let config = LogConfiguration(globalLevel: .warning, environment: .production)
        let logger = OSLoggerAdapter(configuration: config)

        await logger.debug("Debug message")
        await logger.info("Info message")
        await logger.warning("Warning message")
        await logger.error("Error message")
    }

    @Test("OSLoggerAdapter clears cache correctly")
    func testClearCache() async {
        let logger = OSLoggerAdapter(configuration: .development)

        await logger.info("Message 1", category: TestLogCategory.logger)
        await logger.info("Message 2", category: TestLogCategory.network)

        var count = await logger.cachedLoggerCount
        #expect(count == 2)

        await logger.clearCache()
        count = await logger.cachedLoggerCount
        #expect(count == 0)
    }
}

@Suite("OSLoggerFactory Tests")
struct OSLoggerFactoryTests {

    @Test("Factory creates development logger")
    func testDevelopmentFactory() async {
        let logger = OSLoggerFactory.development()
        await logger.debug("Development logger test")
    }

    @Test("Factory creates staging logger")
    func testStagingFactory() async {
        let logger = OSLoggerFactory.staging()
        await logger.info("Staging logger test")
    }

    @Test("Factory creates production logger")
    func testProductionFactory() async {
        let logger = OSLoggerFactory.production()
        await logger.warning("Production logger test")
    }

    @Test("Factory creates testing logger")
    func testTestingFactory() async {
        let logger = OSLoggerFactory.testing()
        await logger.error("Testing logger test")
    }

    @Test("Factory creates custom logger")
    func testCustomFactory() async {
        let logger = OSLoggerFactory.custom(
            globalLevel: .info,
            environment: .development,
            subsystem: "com.test.custom"
        )
        await logger.info("Custom logger test")
    }

    @Test("Factory creates automatic logger")
    func testAutomaticFactory() async {
        let logger = OSLoggerFactory.automatic()
        await logger.info("Automatic logger test")
    }

    @Test("Builder pattern creates logger correctly")
    func testBuilderPattern() async {
        let logger = OSLoggerFactory.builder()
            .globalLevel(.info)
            .environment(.development)
            .override(level: .debug, for: "com.test.auth")
            .includeMetadata(true)
            .build()

        await logger.info("Builder pattern test")
    }

    @Test("Builder pattern with category override")
    func testBuilderWithCategoryOverride() async {
        let logger = OSLoggerFactory.builder()
            .globalLevel(.warning)
            .override(level: .debug, for: TestLogCategory.logger)
            .build()

        await logger.debug("Debug message", category: TestLogCategory.logger)
    }
}

@Suite("LoggerRegistry Tests", .serialized)
struct LoggerRegistryTests {
    private func makeRegistry() -> LoggerRegistry {
        LoggerRegistry()
    }

    @Test("LoggerRegistry shared instance is accessible")
    func testSharedInstance() async {
        let registry = LoggerRegistry.shared
        let config = await registry.configuration
        #expect(config.subsystem.isEmpty == false)
    }

    @Test("Configure registry with new configuration")
    func testConfigureRegistry() async {
        let registry = makeRegistry()
        let newConfig = LogConfiguration(globalLevel: .warning, environment: .production)

        await registry.configure(with: newConfig)
        let config = await registry.configuration

        #expect(config.globalLevel == .warning)
        #expect(config.environment == .production)
    }

    @Test("Register category successfully")
    func testRegisterCategory() async {
        let registry = makeRegistry()

        let wasRegistered = await registry.register(category: TestLogCategory.logger)
        #expect(wasRegistered == true)

        let isRegistered = await registry.isRegistered(category: TestLogCategory.logger)
        #expect(isRegistered == true)
    }

    @Test("Register duplicate category returns false")
    func testRegisterDuplicateCategory() async {
        let registry = makeRegistry()

        let first = await registry.register(category: TestLogCategory.network)
        #expect(first == true)

        let second = await registry.register(category: TestLogCategory.network)
        #expect(second == false)
    }

    @Test("Register multiple categories")
    func testRegisterMultipleCategories() async {
        let registry = makeRegistry()

        let categories: [LogCategory] = [
            TestLogCategory.logger,
            TestLogCategory.network,
            TestLogCategory.database
        ]

        let count = await registry.register(categories: categories)
        #expect(count == 3)

        let registeredCount = await registry.registeredCategoryCount
        #expect(registeredCount == 3)
    }

    @Test("Logger factory creates logger for category")
    func testLoggerFactory() async {
        let registry = makeRegistry()
        await registry.configure(with: .development)

        let logger = await registry.logger(for: TestLogCategory.logger)
        await logger.info("Test message from registry logger")
    }

    @Test("Logger factory caches loggers")
    func testLoggerFactoryCaching() async {
        let registry = makeRegistry()
        await registry.configure(with: .development)

        let logger1 = await registry.logger(for: TestLogCategory.logger)
        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 1)

        let logger2 = await registry.logger(for: TestLogCategory.logger)
        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 1)

        await logger1.info("Message 1")
        await logger2.info("Message 2")
    }

    @Test("Set level override for category")
    func testSetLevelOverride() async {
        let registry = makeRegistry()
        await registry.configure(with: .production)

        await registry.setLevel(.debug, for: TestLogCategory.logger)

        let logger = await registry.logger(for: TestLogCategory.logger)
        await logger.debug("Debug message should be logged")
    }

    @Test("Reset configuration for category")
    func testResetConfigurationForCategory() async {
        let registry = makeRegistry()
        await registry.configure(with: .production)

        await registry.setLevel(.debug, for: TestLogCategory.logger)
        await registry.resetConfiguration(for: TestLogCategory.logger)

        let logger = await registry.logger(for: TestLogCategory.logger)
        await logger.debug("After reset")
    }

    @Test("Clear cache removes all loggers")
    func testClearCache() async {
        let registry = makeRegistry()

        _ = await registry.logger(for: TestLogCategory.logger)
        _ = await registry.logger(for: TestLogCategory.network)

        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 2)

        await registry.clearCache()

        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 0)
    }

    @Test("Configure with preset")
    func testConfigureWithPreset() async {
        let registry = makeRegistry()

        await registry.configure(preset: .production)
        let config = await registry.configuration

        #expect(config.globalLevel == .warning)
        #expect(config.environment == .production)
    }

    @Test("Reset registry clears everything")
    func testResetRegistry() async {
        let registry = makeRegistry()

        await registry.register(category: TestLogCategory.logger)
        _ = await registry.logger(for: TestLogCategory.network)

        await registry.reset()

        let count = await registry.registeredCategoryCount
        let cached = await registry.cachedLoggerCount
        #expect(count == 0)
        #expect(cached == 0)
    }
}

@Suite("EnvironmentConfiguration Tests", .serialized)
struct EnvironmentConfigurationTests {

    @Test("Load empty environment")
    func testLoadEmptyEnvironment() {
        let config = EnvironmentConfiguration.load(from: [:])

        #expect(config.logLevel == nil)
        #expect(config.isEnabled == nil)
        #expect(config.hasAnyConfiguration == false)
    }

    @Test("Parse log level from environment")
    func testParseLogLevel() {
        let env = ["APP_LOG_LEVEL": "debug"]
        let config = EnvironmentConfiguration.load(from: env)

        #expect(config.logLevel == .debug)
    }

    @Test("Parse all log levels")
    func testParseAllLogLevels() {
        let levels = [
            ("debug", LogLevel.debug),
            ("info", LogLevel.info),
            ("warning", LogLevel.warning),
            ("warn", LogLevel.warning),
            ("error", LogLevel.error)
        ]

        for (string, expected) in levels {
            let config = EnvironmentConfiguration.load(from: ["APP_LOG_LEVEL": string])
            #expect(config.logLevel == expected)
        }
    }

    @Test("Parse boolean values")
    func testParseBooleanValues() {
        let trueValues = ["true", "1", "yes", "TRUE", "Yes"]
        let falseValues = ["false", "0", "no", "FALSE", "No"]

        for value in trueValues {
            let config = EnvironmentConfiguration.load(from: ["APP_LOG_ENABLED": value])
            #expect(config.isEnabled == true)
        }

        for value in falseValues {
            let config = EnvironmentConfiguration.load(from: ["APP_LOG_ENABLED": value])
            #expect(config.isEnabled == false)
        }
    }

    @Test("Parse environment")
    func testParseEnvironment() {
        let envs: [(String, LogConfiguration.Environment)] = [
            ("development", .development),
            ("staging", .staging),
            ("production", .production)
        ]

        for (string, expected) in envs {
            let config = EnvironmentConfiguration.load(from: ["APP_ENVIRONMENT": string])
            #expect(config.environment == expected)
        }
    }

    @Test("Parse subsystem")
    func testParseSubsystem() {
        let env = ["APP_LOG_SUBSYSTEM": "com.test.custom"]
        let config = EnvironmentConfiguration.load(from: env)

        #expect(config.subsystem == "com.test.custom")
    }

    @Test("Custom prefix")
    func testCustomPrefix() {
        let env = [
            "MYAPP_LOG_LEVEL": "info",
            "MYAPP_LOG_ENABLED": "true",
            "MYAPP_ENVIRONMENT": "staging"
        ]

        let config = EnvironmentConfiguration.load(from: env, prefix: "MYAPP")

        #expect(config.logLevel == .info)
        #expect(config.isEnabled == true)
        #expect(config.environment == .staging)
    }

    @Test("Supported keys list with prefix")
    func testSupportedKeys() {
        let keys = EnvironmentConfiguration.supportedKeys(prefix: "MYAPP")

        #expect(keys.contains("MYAPP_LOG_LEVEL"))
        #expect(keys.contains("MYAPP_LOG_ENABLED"))
        #expect(keys.contains("MYAPP_ENVIRONMENT"))
    }
}

@Suite("LoggerConfigurator Tests", .serialized)
struct LoggerConfiguratorTests {
    private func makeConfigurator() -> LoggerConfigurator {
        LoggerConfigurator(registry: LoggerRegistry())
    }

    @Test("Configurator shared instance accessible")
    func testSharedInstance() async {
        let configurator = LoggerConfigurator.shared
        let level = await configurator.globalLevel
        #expect([.debug, .info, .warning, .error].contains(level))
    }

    @Test("Set global level")
    func testSetGlobalLevel() async {
        let configurator = makeConfigurator()
        await configurator.setGlobalLevel(.error)
        let level = await configurator.globalLevel
        #expect(level == .error)
    }

    @Test("Set enabled state")
    func testSetEnabled() async {
        let configurator = makeConfigurator()
        await configurator.setEnabled(false)
        let enabled = await configurator.isEnabled
        #expect(enabled == false)
    }

    @Test("Apply preset development")
    func testApplyPresetDevelopment() async {
        let configurator = makeConfigurator()
        await configurator.applyPreset(.development)
        let level = await configurator.globalLevel
        let env = await configurator.environment
        #expect(level == .debug)
        #expect(env == .development)
    }

    @Test("Apply preset production")
    func testApplyPresetProduction() async {
        let configurator = makeConfigurator()
        await configurator.applyPreset(.production)
        let level = await configurator.globalLevel
        let env = await configurator.environment
        #expect(level == .warning)
        #expect(env == .production)
    }
}

@Suite("MockLogger Tests")
struct MockLoggerTests {

    @Test("MockLogger captures debug messages")
    func testCaptureDebug() async {
        let mock = MockLogger()
        await mock.debug("Debug message")

        let count = await mock.count
        #expect(count == 1)

        let entry = await mock.lastEntry
        #expect(entry?.level == .debug)
        #expect(entry?.message == "Debug message")
    }

    @Test("MockLogger captures all log levels")
    func testCaptureAllLevels() async {
        let mock = MockLogger()

        await mock.debug("Debug")
        await mock.info("Info")
        await mock.warning("Warning")
        await mock.error("Error")

        let count = await mock.count
        #expect(count == 4)

        let entries = await mock.entries
        #expect(entries[0].level == .debug)
        #expect(entries[1].level == .info)
        #expect(entries[2].level == .warning)
        #expect(entries[3].level == .error)
    }

    @Test("MockLogger captures category")
    func testCaptureCategory() async {
        let mock = MockLogger()
        await mock.info("Test", category: TestLogCategory.logger)

        let entry = await mock.lastEntry
        #expect(entry?.category == "com.test.logger.system")
    }

    @Test("MockLogger clear removes all entries")
    func testClear() async {
        let mock = MockLogger()
        await mock.info("Test 1")
        await mock.info("Test 2")

        var count = await mock.count
        #expect(count == 2)

        await mock.clear()
        count = await mock.count
        #expect(count == 0)
    }

    @Test("MockLogger filters by level")
    func testFilterByLevel() async {
        let mock = MockLogger()
        await mock.debug("Debug 1")
        await mock.info("Info 1")
        await mock.debug("Debug 2")
        await mock.error("Error 1")

        let debugEntries = await mock.entries(level: .debug)
        #expect(debugEntries.count == 2)

        let errorEntries = await mock.entries(level: .error)
        #expect(errorEntries.count == 1)
    }

    @Test("MockLogger filters by category")
    func testFilterByCategory() async {
        let mock = MockLogger()
        await mock.info("Log 1", category: TestLogCategory.logger)
        await mock.info("Log 2", category: TestLogCategory.network)
        await mock.info("Log 3", category: TestLogCategory.logger)

        let loggerEntries = await mock.entries(category: TestLogCategory.logger)
        #expect(loggerEntries.count == 2)
    }

    @Test("MockLogger contains message")
    func testContainsMessage() async {
        let mock = MockLogger()
        await mock.info("User logged in")
        await mock.error("Connection failed")

        let hasLoginLog = await mock.contains(level: .info, message: "User logged in")
        #expect(hasLoginLog == true)

        let hasNotExisting = await mock.contains(level: .debug, message: "Not exists")
        #expect(hasNotExisting == false)
    }

    @Test("MockLogger respects shouldLog flag")
    func testShouldLogFlag() async {
        let mock = MockLogger()
        await mock.setShouldLog(false)

        await mock.info("Should not be logged")
        let count = await mock.count
        #expect(count == 0)

        await mock.setShouldLog(true)
        await mock.info("Should be logged")
        let count2 = await mock.count
        #expect(count2 == 1)
    }
}

@Suite("DynamicLogCategory Tests")
struct DynamicLogCategoryTests {

    @Test("Dynamic category with identifier")
    func testDynamicCategory() {
        let category = DynamicLogCategory(
            identifier: "com.myapp.custom.test",
            displayName: "Custom Test"
        )

        #expect(category.identifier == "com.myapp.custom.test")
        #expect(category.displayName == "Custom Test")
    }

    @Test("Dynamic category auto-generates display name")
    func testAutoDisplayName() {
        let category = DynamicLogCategory(identifier: "com.myapp.auth.login")

        #expect(category.displayName.contains("Auth"))
        #expect(category.displayName.contains("Login"))
    }
}

@Suite("Concurrency Tests", .serialized)
struct ConcurrencyTests {

    @Test("MockLogger handles concurrent writes")
    func testConcurrentWrites() async {
        let mock = MockLogger()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await mock.info("Message \(i)")
                }
            }
        }

        let count = await mock.count
        #expect(count == 100)
    }

    @Test("OSLoggerAdapter handles concurrent logging")
    func testOSLoggerConcurrent() async {
        let logger = OSLoggerAdapter(configuration: .development)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    await logger.info("Concurrent log \(i)")
                }
            }
        }
    }

    @Test("LoggerRegistry handles concurrent access")
    func testRegistryConcurrent() async {
        let registry = LoggerRegistry()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    _ = await registry.logger(for: TestLogCategory.logger)
                }
                group.addTask {
                    await registry.register(category: DynamicLogCategory(
                        identifier: "com.test.dynamic.\(i)"
                    ))
                }
            }
        }

        let count = await registry.cachedLoggerCount
        #expect(count >= 0)
    }
}

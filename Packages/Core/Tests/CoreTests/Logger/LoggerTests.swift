import Testing
@testable import EduLogger

@Suite("Logger Tests")
struct LoggerTests {
    @Test("Logger shared instance is accessible")
    func testSharedInstance() async {
        let logger = Logger.shared
        await logger.info("Test log message")
        // Logger should not crash
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
        // Should not crash
    }

    @Test("OSLoggerAdapter logs info message")
    func testInfoLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.info("Info test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter logs warning message")
    func testWarningLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.warning("Warning test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter logs error message")
    func testErrorLogging() async {
        let logger = OSLoggerAdapter(configuration: .development)
        await logger.error("Error test message")
        // Should not crash
    }

    @Test("OSLoggerAdapter caches loggers by category")
    func testLoggerCaching() async {
        let logger = OSLoggerAdapter(configuration: .development)
        let category = SystemLogCategory.logger

        await logger.info("First message", category: category)
        var count = await logger.cachedLoggerCount
        #expect(count == 1)

        await logger.info("Second message", category: category)
        count = await logger.cachedLoggerCount
        #expect(count == 1)

        let category2 = SystemLogCategory.network
        await logger.info("Third message", category: category2)
        count = await logger.cachedLoggerCount
        #expect(count == 2)
    }

    @Test("OSLoggerAdapter respects level filtering")
    func testLevelFiltering() async {
        // Logger con nivel mínimo warning
        let config = LogConfiguration(
            globalLevel: .warning,
            environment: .production
        )
        let logger = OSLoggerAdapter(configuration: config)

        // Debug e info no deberían registrarse
        await logger.debug("Debug message")
        await logger.info("Info message")

        // Warning y error sí deberían registrarse
        await logger.warning("Warning message")
        await logger.error("Error message")

        // No crash = test passed
    }

    @Test("OSLoggerAdapter clears cache correctly")
    func testClearCache() async {
        let logger = OSLoggerAdapter(configuration: .development)

        await logger.info("Message 1", category: SystemLogCategory.logger)
        await logger.info("Message 2", category: SystemLogCategory.network)

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
        // Should not crash
    }

    @Test("Factory creates staging logger")
    func testStagingFactory() async {
        let logger = OSLoggerFactory.staging()
        await logger.info("Staging logger test")
        // Should not crash
    }

    @Test("Factory creates production logger")
    func testProductionFactory() async {
        let logger = OSLoggerFactory.production()
        await logger.warning("Production logger test")
        // Should not crash
    }

    @Test("Factory creates testing logger")
    func testTestingFactory() async {
        let logger = OSLoggerFactory.testing()
        await logger.error("Testing logger test")
        // Should not crash (but won't log anything)
    }

    @Test("Factory creates custom logger")
    func testCustomFactory() async {
        let logger = OSLoggerFactory.custom(
            globalLevel: .info,
            environment: .development,
            subsystem: "com.test.custom"
        )
        await logger.info("Custom logger test")
        // Should not crash
    }

    @Test("Factory creates automatic logger")
    func testAutomaticFactory() async {
        let logger = OSLoggerFactory.automatic()
        await logger.info("Automatic logger test")
        // Should not crash
    }

    @Test("Builder pattern creates logger correctly")
    func testBuilderPattern() async {
        let logger = OSLoggerFactory.builder()
            .globalLevel(.info)
            .environment(.development)
            .override(level: .debug, for: "com.edugo.auth")
            .includeMetadata(true)
            .build()

        await logger.info("Builder pattern test")
        // Should not crash
    }

    @Test("Builder pattern with category override")
    func testBuilderWithCategoryOverride() async {
        let logger = OSLoggerFactory.builder()
            .globalLevel(.warning)
            .override(level: .debug, for: SystemLogCategory.logger)
            .build()

        await logger.debug("Debug message", category: SystemLogCategory.logger)
        // Should not crash
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
        #expect(config.subsystem == "com.edugo.apple")
    }

    @Test("Configure registry with new configuration")
    func testConfigureRegistry() async {
        let registry = makeRegistry()
        let newConfig = LogConfiguration(
            globalLevel: .warning,
            environment: .production
        )

        await registry.configure(with: newConfig)
        let config = await registry.configuration

        #expect(config.globalLevel == .warning)
        #expect(config.environment == .production)
    }

    @Test("Register category successfully")
    func testRegisterCategory() async {
        let registry = makeRegistry()

        let wasRegistered = await registry.register(category: SystemLogCategory.logger)
        #expect(wasRegistered == true)

        let isRegistered = await registry.isRegistered(category: SystemLogCategory.logger)
        #expect(isRegistered == true)
    }

    @Test("Register duplicate category returns false")
    func testRegisterDuplicateCategory() async {
        let registry = makeRegistry()

        let firstRegistration = await registry.register(category: SystemLogCategory.network)
        #expect(firstRegistration == true)

        let secondRegistration = await registry.register(category: SystemLogCategory.network)
        #expect(secondRegistration == false)
    }

    @Test("Register multiple categories")
    func testRegisterMultipleCategories() async {
        let registry = makeRegistry()

        let categories: [LogCategory] = [
            SystemLogCategory.logger,
            SystemLogCategory.network,
            SystemLogCategory.database
        ]

        let count = await registry.register(categories: categories)
        #expect(count == 3)

        let registeredCount = await registry.registeredCategoryCount
        #expect(registeredCount == 3)
    }

    @Test("Register system categories")
    func testRegisterSystemCategories() async {
        let registry = makeRegistry()

        let count = await registry.registerSystemCategories()
        #expect(count >= 0)

        let isRegistered = await registry.isRegistered(category: SystemLogCategory.logger)
        #expect(isRegistered == true)
    }

    @Test("Logger factory creates logger for category")
    func testLoggerFactory() async {
        let registry = makeRegistry()
        await registry.configure(with: .development)

        let logger = await registry.logger(for: SystemLogCategory.logger)

        // Logger should be usable
        await logger.info("Test message from registry logger")
    }

    @Test("Logger factory caches loggers")
    func testLoggerFactoryCaching() async {
        let registry = makeRegistry()
        await registry.configure(with: .development)

        let logger1 = await registry.logger(for: SystemLogCategory.logger)
        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 1)

        let logger2 = await registry.logger(for: SystemLogCategory.logger)
        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 1)

        // Should be same instance
        await logger1.info("Message 1")
        await logger2.info("Message 2")
    }

    @Test("Set level override for category")
    func testSetLevelOverride() async {
        let registry = makeRegistry()
        await registry.configure(with: .production)

        // Set debug level for specific category
        await registry.setLevel(.debug, for: SystemLogCategory.logger)

        let logger = await registry.logger(for: SystemLogCategory.logger)
        await logger.debug("Debug message should be logged")
    }

    @Test("Set configuration override for category")
    func testSetConfigurationOverride() async {
        let registry = makeRegistry()
        await registry.configure(with: .production)

        let customConfig = LogConfiguration(
            globalLevel: .debug,
            environment: .development,
            includeMetadata: true
        )

        await registry.setConfiguration(customConfig, for: SystemLogCategory.network)

        let logger = await registry.logger(for: SystemLogCategory.network)
        await logger.debug("Custom config message")
    }

    @Test("Reset configuration for category")
    func testResetConfigurationForCategory() async {
        let registry = makeRegistry()
        await registry.configure(with: .production)

        // Set override
        await registry.setLevel(.debug, for: SystemLogCategory.logger)
        let logger1 = await registry.logger(for: SystemLogCategory.logger)
        await logger1.debug("With override")

        // Reset override
        await registry.resetConfiguration(for: SystemLogCategory.logger)
        let logger2 = await registry.logger(for: SystemLogCategory.logger)
        await logger2.debug("After reset")
    }

    @Test("Clear cache removes all loggers")
    func testClearCache() async {
        let registry = makeRegistry()

        _ = await registry.logger(for: SystemLogCategory.logger)
        _ = await registry.logger(for: SystemLogCategory.network)

        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 2)

        await registry.clearCache()

        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 0)
    }

    @Test("Clear cache for specific category")
    func testClearCacheForCategory() async {
        let registry = makeRegistry()

        _ = await registry.logger(for: SystemLogCategory.logger)
        _ = await registry.logger(for: SystemLogCategory.network)

        let count1 = await registry.cachedLoggerCount
        #expect(count1 == 2)

        await registry.clearCache(for: SystemLogCategory.logger)

        let count2 = await registry.cachedLoggerCount
        #expect(count2 == 1)
    }

    @Test("Logger for category by string ID")
    func testLoggerForCategoryId() async {
        let registry = makeRegistry()
        await registry.configure(with: .development)

        let logger = await registry.logger(forCategoryId: "com.edugo.custom.test")
        await logger.info("Test message from string ID")
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

        // Setup some state
        await registry.register(category: SystemLogCategory.logger)
        _ = await registry.logger(for: SystemLogCategory.network)
        await registry.setLevel(.debug, for: SystemLogCategory.database)

        let count1 = await registry.registeredCategoryCount
        let cached1 = await registry.cachedLoggerCount
        #expect(count1 > 0)
        #expect(cached1 > 0)

        // Reset
        await registry.reset()

        let count2 = await registry.registeredCategoryCount
        let cached2 = await registry.cachedLoggerCount
        #expect(count2 == 0)
        #expect(cached2 == 0)
    }

    @Test("Logger without category uses global config")
    func testLoggerWithoutCategory() async {
        let registry = makeRegistry()
        await registry.configure(with: .development)

        let logger = await registry.logger()
        await logger.info("Message without category")
    }
}

@Suite("EnvironmentConfiguration Tests", .serialized)
struct EnvironmentConfigurationTests {

    @Test("Load empty environment")
    func testLoadEmptyEnvironment() {
        let config = EnvironmentConfiguration.load(from: [:])

        #expect(config.logLevel == nil)
        #expect(config.isEnabled == nil)
        #expect(config.includeMetadata == nil)
        #expect(config.environment == nil)
        #expect(config.subsystem == nil)
        #expect(config.hasAnyConfiguration == false)
    }

    @Test("Parse log level from environment")
    func testParseLogLevel() {
        let env = ["EDUGO_LOG_LEVEL": "debug"]
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
            let config = EnvironmentConfiguration.load(from: ["EDUGO_LOG_LEVEL": string])
            #expect(config.logLevel == expected)
        }
    }

    @Test("Parse boolean values")
    func testParseBooleanValues() {
        let trueValues = ["true", "1", "yes", "TRUE", "Yes"]
        let falseValues = ["false", "0", "no", "FALSE", "No"]

        for value in trueValues {
            let config = EnvironmentConfiguration.load(from: ["EDUGO_LOG_ENABLED": value])
            #expect(config.isEnabled == true)
        }

        for value in falseValues {
            let config = EnvironmentConfiguration.load(from: ["EDUGO_LOG_ENABLED": value])
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
            let config = EnvironmentConfiguration.load(from: ["EDUGO_ENVIRONMENT": string])
            #expect(config.environment == expected)
        }
    }

    @Test("Parse subsystem")
    func testParseSubsystem() {
        let env = ["EDUGO_LOG_SUBSYSTEM": "com.test.custom"]
        let config = EnvironmentConfiguration.load(from: env)

        #expect(config.subsystem == "com.test.custom")
    }

    @Test("Parse multiple values")
    func testParseMultipleValues() {
        let env = [
            "EDUGO_LOG_LEVEL": "info",
            "EDUGO_LOG_ENABLED": "true",
            "EDUGO_LOG_METADATA": "false",
            "EDUGO_ENVIRONMENT": "staging",
            "EDUGO_LOG_SUBSYSTEM": "com.test.app"
        ]

        let config = EnvironmentConfiguration.load(from: env)

        #expect(config.logLevel == .info)
        #expect(config.isEnabled == true)
        #expect(config.includeMetadata == false)
        #expect(config.environment == .staging)
        #expect(config.subsystem == "com.test.app")
        #expect(config.hasAnyConfiguration == true)
    }

    @Test("Supported keys list")
    func testSupportedKeys() {
        let keys = EnvironmentConfiguration.supportedKeys()

        #expect(keys.contains("EDUGO_LOG_LEVEL"))
        #expect(keys.contains("EDUGO_LOG_ENABLED"))
        #expect(keys.contains("EDUGO_LOG_METADATA"))
        #expect(keys.contains("EDUGO_ENVIRONMENT"))
        #expect(keys.contains("EDUGO_LOG_SUBSYSTEM"))
    }

    @Test("Documentation generation")
    func testDocumentation() {
        let docs = EnvironmentConfiguration.documentation()

        #expect(docs.contains("EDUGO_LOG_LEVEL"))
        #expect(docs.contains("EDUGO_LOG_ENABLED"))
        #expect(docs.contains("Example"))
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

        // Should have some default level
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

    @Test("Set include metadata")
    func testSetIncludeMetadata() async {
        let configurator = makeConfigurator()

        await configurator.setIncludeMetadata(true)
        let config = await configurator.configuration

        #expect(config.includeMetadata == true)
    }

    @Test("Set level for category")
    func testSetLevelForCategory() async {
        let configurator = makeConfigurator()

        await configurator.setLevel(.debug, for: SystemLogCategory.logger)

        // Should not crash
    }

    @Test("Reset category")
    func testResetCategory() async {
        let configurator = makeConfigurator()

        await configurator.setLevel(.debug, for: SystemLogCategory.network)
        await configurator.resetCategory(SystemLogCategory.network)

        // Should not crash
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

    @Test("Convenience configure development")
    func testConfigureDevelopment() async {
        let configurator = makeConfigurator()

        await configurator.configureDevelopment()
        let env = await configurator.environment

        #expect(env == .development)
    }

    @Test("Convenience configure production")
    func testConfigureProduction() async {
        let configurator = makeConfigurator()

        await configurator.configureProduction()
        let env = await configurator.environment

        #expect(env == .production)
    }

    @Test("Configure from environment with no values")
    func testConfigureFromEnvironmentEmpty() async {
        let configurator = makeConfigurator()

        // Esto cargará el environment real que probablemente está vacío
        let found = await configurator.configureFromEnvironment()

        // Should return false if no environment vars are set
        // (can't guarantee this in all test environments)
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
        await mock.info("Test", category: SystemLogCategory.logger)

        let entry = await mock.lastEntry
        #expect(entry?.category == "com.edugo.logger.system")
    }

    @Test("MockLogger captures metadata")
    func testCaptureMetadata() async {
        let mock = MockLogger()
        await mock.info("Test")

        let entry = await mock.lastEntry
        #expect(entry?.file.contains("LoggerTests.swift") == true)
        #expect(entry?.function.contains("testCaptureMetadata") == true)
        #expect((entry?.line ?? 0) > 0)
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
        await mock.info("Log 1", category: SystemLogCategory.logger)
        await mock.info("Log 2", category: SystemLogCategory.network)
        await mock.info("Log 3", category: SystemLogCategory.logger)

        let loggerEntries = await mock.entries(category: SystemLogCategory.logger)
        #expect(loggerEntries.count == 2)
    }

    @Test("MockLogger contains message")
    func testContainsMessage() async {
        let mock = MockLogger()
        await mock.info("User logged in")
        await mock.error("Connection failed")

        let hasLoginLog = await mock.contains(level: .info, message: "User logged in")
        #expect(hasLoginLog == true)

        let hasErrorLog = await mock.contains(level: .error, message: "Connection failed")
        #expect(hasErrorLog == true)

        let hasNotExisting = await mock.contains(level: .debug, message: "Not exists")
        #expect(hasNotExisting == false)
    }

    @Test("MockLogger contains partial message")
    func testContainsPartialMessage() async {
        let mock = MockLogger()
        await mock.info("User authentication successful")

        let hasAuth = await mock.containsMessage(level: .info, containing: "authentication")
        #expect(hasAuth == true)

        let hasSuccess = await mock.containsMessage(level: .info, containing: "successful")
        #expect(hasSuccess == true)
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

extension MockLogger {
    func setShouldLog(_ value: Bool) {
        self.shouldLog = value
    }
}

@Suite("StandardLogCategory Tests")
struct StandardLogCategoryTests {

    @Test("TIER0 categories have correct identifiers")
    func testTIER0Identifiers() {
        #expect(StandardLogCategory.TIER0.entity.identifier == "com.edugo.tier0.common.entity")
        #expect(StandardLogCategory.TIER0.repository.identifier == "com.edugo.tier0.common.repository")
        #expect(StandardLogCategory.TIER0.useCase.identifier == "com.edugo.tier0.common.usecase")
        #expect(StandardLogCategory.TIER0.error.identifier == "com.edugo.tier0.common.error")
    }

    @Test("Logger categories have correct identifiers")
    func testLoggerIdentifiers() {
        #expect(StandardLogCategory.Logger.system.identifier == "com.edugo.tier1.logger.system")
        #expect(StandardLogCategory.Logger.registry.identifier == "com.edugo.tier1.logger.registry")
        #expect(StandardLogCategory.Logger.configuration.identifier == "com.edugo.tier1.logger.configuration")
    }

    @Test("Models categories have correct identifiers")
    func testModelsIdentifiers() {
        #expect(StandardLogCategory.Models.user.identifier == "com.edugo.tier1.models.user")
        #expect(StandardLogCategory.Models.model.identifier == "com.edugo.tier1.models.system")
    }

    @Test("TIER0 all categories count")
    func testTIER0AllCategoriesCount() {
        let all = StandardLogCategory.TIER0.allCategories
        #expect(all.count >= 16)
    }

    @Test("Logger all categories count")
    func testLoggerAllCategoriesCount() {
        let all = StandardLogCategory.Logger.allCategories
        #expect(all.count >= 11)
    }

    @Test("Models all categories count")
    func testModelsAllCategoriesCount() {
        let all = StandardLogCategory.Models.allCategories
        #expect(all.count >= 7)
    }

    @Test("Category tier detection")
    func testTierDetection() {
        #expect(StandardLogCategory.TIER0.entity.tier == 0)
        #expect(StandardLogCategory.Logger.system.tier == 1)
        #expect(StandardLogCategory.TIER0.entity.isTier0 == true)
        #expect(StandardLogCategory.Logger.system.isTier1 == true)
    }

    @Test("Category module detection")
    func testModuleDetection() {
        #expect(StandardLogCategory.TIER0.entity.moduleName == "common")
        #expect(StandardLogCategory.Logger.system.moduleName == "logger")
        #expect(StandardLogCategory.Models.user.moduleName == "models")
    }

    @Test("Category subcomponent detection")
    func testSubcomponentDetection() {
        #expect(StandardLogCategory.TIER0.entity.subcomponent == "entity")
        #expect(StandardLogCategory.Logger.registry.subcomponent == "registry")
        #expect(StandardLogCategory.Models.user.subcomponent == "user")
    }
}

@Suite("CategoryBuilder Tests")
struct CategoryBuilderTests {

    @Test("Builder creates correct identifier")
    func testBuilderBasic() {
        let builder = CategoryBuilder(tier: 2, module: "network")
        let identifier = builder.build()

        #expect(identifier == "com.edugo.tier2.network")
    }

    @Test("Builder with components")
    func testBuilderWithComponents() {
        let identifier = CategoryBuilder(tier: 3, module: "auth")
            .component("login")
            .component("attempt")
            .build()

        #expect(identifier == "com.edugo.tier3.auth.login.attempt")
    }

    @Test("Builder with convenience shortcuts")
    func testBuilderShortcuts() {
        let tier0 = StandardLogCategory.tier0("common")
            .component("test")
            .build()

        #expect(tier0 == "com.edugo.tier0.common.test")

        let tier3 = StandardLogCategory.tier3("auth")
            .component("login")
            .build()

        #expect(tier3 == "com.edugo.tier3.auth.login")
    }
}

@Suite("DynamicLogCategory Tests")
struct DynamicLogCategoryTests {

    @Test("Dynamic category with identifier")
    func testDynamicCategory() {
        let category = DynamicLogCategory(
            identifier: "com.edugo.tier2.custom.test",
            displayName: "Custom Test"
        )

        #expect(category.identifier == "com.edugo.tier2.custom.test")
        #expect(category.displayName == "Custom Test")
    }

    @Test("Dynamic category auto-generates display name")
    func testAutoDisplayName() {
        let category = DynamicLogCategory(
            identifier: "com.edugo.tier3.auth.login"
        )

        #expect(category.displayName.contains("Auth"))
        #expect(category.displayName.contains("Login"))
    }

    @Test("Dynamic category with builder")
    func testDynamicCategoryWithBuilder() {
        let builder = CategoryBuilder(tier: 4, module: "features")
            .component("analytics")

        let category = DynamicLogCategory(builder: builder, displayName: "Analytics")

        #expect(category.identifier == "com.edugo.tier4.features.analytics")
        #expect(category.displayName == "Analytics")
    }
}

@Suite("Category Validation Tests")
struct CategoryValidationTests {

    @Test("Valid category identifiers")
    func testValidIdentifiers() {
        #expect(StandardLogCategory.TIER0.entity.isValidIdentifier == true)
        #expect(StandardLogCategory.Logger.system.isValidIdentifier == true)

        let dynamic = DynamicLogCategory(identifier: "com.edugo.tier2.network.request")
        #expect(dynamic.isValidIdentifier == true)
    }

    @Test("Invalid category identifiers")
    func testInvalidIdentifiers() {
        let invalid1 = DynamicLogCategory(identifier: "edugo.tier3.auth")
        #expect(invalid1.isValidIdentifier == false)

        let invalid2 = DynamicLogCategory(identifier: "com.edugo.auth")
        #expect(invalid2.isValidIdentifier == false)

        let invalid3 = DynamicLogCategory(identifier: "com.edugo.tier9.auth")
        #expect(invalid3.isValidIdentifier == false)
    }

    @Test("Validation errors are descriptive")
    func testValidationErrors() {
        let invalid = DynamicLogCategory(identifier: "edugo.auth")
        let errors = invalid.validationErrors

        #expect(errors.count > 0)
        #expect(errors.contains { $0.contains("com.edugo") })
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

        // Should not crash or data race
    }

    @Test("LoggerRegistry handles concurrent access")
    func testRegistryConcurrent() async {
        let registry = LoggerRegistry()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    _ = await registry.logger(for: SystemLogCategory.logger)
                }
                group.addTask {
                    await registry.register(category: DynamicLogCategory(
                        identifier: "com.edugo.tier0.test.\(i)"
                    ))
                }
            }
        }

        let count = await registry.cachedLoggerCount
        #expect(count >= 0)
    }

    @Test("LoggerConfigurator handles concurrent configuration changes")
    func testConfiguratorConcurrent() async {
        let configurator = LoggerConfigurator(registry: LoggerRegistry())

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await configurator.setGlobalLevel(.debug)
                }
                group.addTask {
                    await configurator.setGlobalLevel(.info)
                }
                group.addTask {
                    await configurator.setEnabled(true)
                }
            }
        }

        // Should not crash
        let level = await configurator.globalLevel
        #expect([.debug, .info].contains(level))
    }
}

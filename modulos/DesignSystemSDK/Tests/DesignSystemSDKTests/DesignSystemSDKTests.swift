import XCTest
@testable import DesignSystemSDK

// MARK: - Theme Tests

final class ThemeTests: XCTestCase {

    func testDefaultTheme() {
        let theme = Theme.default
        XCTAssertEqual(theme.id, "default")
        XCTAssertEqual(theme.name, "Default")
    }

    func testDarkTheme() {
        let theme = Theme.dark
        XCTAssertEqual(theme.id, "dark")
    }

    func testHighContrastTheme() {
        let theme = Theme.highContrast
        XCTAssertEqual(theme.id, "highContrast")
    }

    func testGrayscaleTheme() {
        let theme = Theme.grayscale
        XCTAssertEqual(theme.id, "grayscale")
    }

    func testCustomTheme() {
        let custom = Theme.custom(
            id: "myTheme",
            name: "My Theme",
            palette: .default
        )
        XCTAssertEqual(custom.id, "myTheme")
        XCTAssertEqual(custom.name, "My Theme")
    }

    func testThemeEquality() {
        let a = Theme.default
        let b = Theme.default
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(Theme.default, Theme.dark)
    }
}

// MARK: - Typography Tests

final class TypographyTests: XCTestCase {

    func testDefaultTypography() {
        let typo = Typography.default
        XCTAssertFalse(typo.fontFamily.isEmpty)
        XCTAssertGreaterThan(typo.baseSize, 0)
    }

    func testCompactTypography() {
        let compact = Typography.compact
        let def = Typography.default
        XCTAssertLessThanOrEqual(compact.baseSize, def.baseSize)
    }

    func testLargeTypography() {
        let large = Typography.large
        let def = Typography.default
        XCTAssertGreaterThanOrEqual(large.baseSize, def.baseSize)
    }
}

// MARK: - Spacing Tests

final class SpacingTests: XCTestCase {

    func testDefaultSpacing() {
        let spacing = Spacing.default
        XCTAssertGreaterThan(spacing.md, 0)
    }

    func testCompactSpacing() {
        let compact = Spacing.compact
        let def = Spacing.default
        XCTAssertLessThanOrEqual(compact.md, def.md)
    }

    func testGenerousSpacing() {
        let generous = Spacing.generous
        let def = Spacing.default
        XCTAssertGreaterThanOrEqual(generous.md, def.md)
    }
}

// MARK: - CornerRadius Tests

final class CornerRadiusTests: XCTestCase {

    func testDefaultCornerRadius() {
        let cr = CornerRadius.default
        XCTAssertGreaterThan(cr.md, 0)
    }

    func testSquareCornerRadius() {
        let square = CornerRadius.square
        XCTAssertEqual(square.sm, 0)
    }

    func testSoftCornerRadius() {
        let soft = CornerRadius.soft
        let def = CornerRadius.default
        XCTAssertGreaterThanOrEqual(soft.md, def.md)
    }
}

// MARK: - Shadows Tests

final class ShadowsTests: XCTestCase {

    func testDefaultShadows() {
        let shadows = Shadows.default
        XCTAssertNotNil(shadows.md)
    }
}

// MARK: - ColorPalette Tests

final class ColorPaletteTests: XCTestCase {

    func testDefaultPalette() {
        let palette = ColorPalette.default
        XCTAssertNotNil(palette.primary)
        XCTAssertNotNil(palette.secondary)
        XCTAssertNotNil(palette.error)
    }

    func testHighContrastPalette() {
        let palette = ColorPalette.highContrast
        XCTAssertNotNil(palette.primary)
    }

    func testGrayscalePalette() {
        let palette = ColorPalette.grayscale
        XCTAssertNotNil(palette.primary)
    }
}

// MARK: - ColorToken Tests

final class ColorTokenTests: XCTestCase {

    func testColorTokenResolveLight() {
        let token = ColorToken(light: .white, dark: .black)
        let resolved = token.resolve(for: .light)
        XCTAssertEqual(resolved, .white)
    }

    func testColorTokenResolveDark() {
        let token = ColorToken(light: .white, dark: .black)
        let resolved = token.resolve(for: .dark)
        XCTAssertEqual(resolved, .black)
    }
}

// MARK: - AccessibilityIdentifier Tests

final class AccessibilityIdentifierTests: XCTestCase {

    func testButtonIdentifier() {
        let id = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        XCTAssertEqual(id.id, "auth_login_button_submit")
    }

    func testTextFieldIdentifier() {
        let id = AccessibilityIdentifier.textField(module: "auth", screen: "login", field: "email")
        XCTAssertEqual(id.id, "auth_login_textfield_email")
    }

    func testToggleIdentifier() {
        let id = AccessibilityIdentifier.toggle(module: "settings", screen: "main", setting: "dark")
        XCTAssertEqual(id.id, "settings_main_toggle_dark")
    }

    func testLinkIdentifier() {
        let id = AccessibilityIdentifier.link(module: "nav", screen: "home", destination: "profile")
        XCTAssertEqual(id.id, "nav_home_link_profile")
    }

    func testTabIdentifier() {
        let id = AccessibilityIdentifier.tab(module: "nav", name: "home")
        XCTAssertEqual(id.id, "nav_tab_home")
    }

    func testCellIdentifier() {
        let id = AccessibilityIdentifier.cell(module: "list", screen: "users", index: 0)
        XCTAssertEqual(id.id, "list_users_cell_0")
    }

    func testCustomIdentifier() {
        let id = AccessibilityIdentifier.custom("my_custom_id")
        XCTAssertEqual(id.id, "my_custom_id")
    }

    func testEquality() {
        let a = AccessibilityIdentifier.custom("test")
        let b = AccessibilityIdentifier.custom("test")
        XCTAssertEqual(a, b)
    }

    func testIsValid() {
        let valid = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        XCTAssertTrue(valid.isValid)

        let invalid = AccessibilityIdentifier.custom("")
        XCTAssertFalse(invalid.isValid)
    }

    func testComponents() {
        let id = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        XCTAssertEqual(id.components, ["auth", "login", "button", "submit"])
    }

    func testModule() {
        let id = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        XCTAssertEqual(id.module, "auth")
    }
}

// MARK: - AccessibilityIdentifierBuilder Tests

final class AccessibilityIdentifierBuilderTests: XCTestCase {

    func testBuilderFlow() {
        let id = AccessibilityIdentifierBuilder()
            .module("auth")
            .screen("login")
            .component("button")
            .descriptor("submit")
            .build()
        XCTAssertEqual(id.id, "auth_login_button_submit")
    }

    func testBuilderWithIndex() {
        let id = AccessibilityIdentifierBuilder()
            .module("list")
            .screen("users")
            .component("cell")
            .index(3)
            .build()
        XCTAssertEqual(id.id, "list_users_cell_3")
    }
}

// MARK: - AccessibilityIdentifier Registry Tests

@MainActor
final class AccessibilityIdentifierRegistryTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        AccessibilityIdentifierRegistry.shared.reset()
    }

    func testRegisterAndCheck() {
        let id = AccessibilityIdentifier.custom("test_register")
        let registry = AccessibilityIdentifierRegistry.shared
        let registered = registry.register(id)
        XCTAssertTrue(registered)
        XCTAssertTrue(registry.isRegistered(id))
    }

    func testDuplicateRegister() {
        let id = AccessibilityIdentifier.custom("test_dup")
        let registry = AccessibilityIdentifierRegistry.shared
        _ = registry.register(id)
        let second = registry.register(id)
        XCTAssertFalse(second)
    }

    func testReset() {
        let id = AccessibilityIdentifier.custom("test_reset")
        let registry = AccessibilityIdentifierRegistry.shared
        _ = registry.register(id)
        registry.reset()
        XCTAssertFalse(registry.isRegistered(id))
    }

    func testAllIdentifiers() {
        let registry = AccessibilityIdentifierRegistry.shared
        _ = registry.register(AccessibilityIdentifier.custom("z_last"))
        _ = registry.register(AccessibilityIdentifier.custom("a_first"))
        let all = registry.allIdentifiers
        XCTAssertEqual(all, ["a_first", "z_last"])
    }
}

// MARK: - EduShadowLevel Tests

@available(macOS 26.0, iOS 26.0, *)
final class EduShadowLevelTests: XCTestCase {

    func testAllCases() {
        XCTAssertGreaterThan(EduShadowLevel.allCases.count, 0)
    }

    func testConfigurationNotNil() {
        for level in EduShadowLevel.allCases {
            let config = level.configuration
            XCTAssertGreaterThanOrEqual(config.radius, 0)
        }
    }
}

// MARK: - EduShadowConfiguration Tests

@available(macOS 26.0, iOS 26.0, *)
final class EduShadowConfigurationTests: XCTestCase {

    func testInit() {
        let config = EduShadowConfiguration(color: .black, radius: 4, x: 0, y: 2)
        XCTAssertEqual(config.radius, 4)
        XCTAssertEqual(config.x, 0)
        XCTAssertEqual(config.y, 2)
    }

    func testEquality() {
        let a = EduShadowConfiguration(color: .black, radius: 4, x: 0, y: 2)
        let b = EduShadowConfiguration(color: .black, radius: 4, x: 0, y: 2)
        XCTAssertEqual(a, b)
    }
}

// MARK: - EduLiquidRoundedRectangle Tests

@available(macOS 26.0, iOS 26.0, *)
final class EduLiquidRoundedRectangleTests: XCTestCase {

    func testInit() {
        let shape = EduLiquidRoundedRectangle(cornerRadius: 16, smoothness: 0.6)
        XCTAssertEqual(shape.cornerRadius, 16)
        XCTAssertEqual(shape.smoothness, 0.6)
    }

    func testDefaultInit() {
        let shape = EduLiquidRoundedRectangle()
        XCTAssertEqual(shape.cornerRadius, 16)
        XCTAssertEqual(shape.smoothness, 0.6)
    }
}

// MARK: - EduMorphableShape Tests

@available(macOS 26.0, iOS 26.0, *)
final class EduMorphableShapeTests: XCTestCase {

    func testCornerFactor() {
        XCTAssertEqual(EduMorphableShape.circle.cornerFactor, .infinity)
        XCTAssertEqual(EduMorphableShape.rectangle.cornerFactor, 0)
    }
}

// MARK: - ScalingMetrics Tests

final class ScalingMetricsEnvironmentTests: XCTestCase {

    func testDefaultSizeCategory() {
        let env = ScalingMetricsEnvironment()
        XCTAssertEqual(env.sizeCategory, .large)
    }

    func testSpacingValues() {
        let env = ScalingMetricsEnvironment()
        XCTAssertGreaterThan(env.spacingXS, 0)
        XCTAssertGreaterThan(env.spacingSM, 0)
        XCTAssertGreaterThan(env.spacingMD, 0)
        XCTAssertGreaterThan(env.spacingLG, 0)
    }

    func testSpacingOrdering() {
        let env = ScalingMetricsEnvironment()
        XCTAssertLessThan(env.spacingXS, env.spacingSM)
        XCTAssertLessThan(env.spacingSM, env.spacingMD)
        XCTAssertLessThan(env.spacingMD, env.spacingLG)
    }
}

// MARK: - ColorSchemePreference Tests

@MainActor
final class ColorSchemePreferenceTests: XCTestCase {

    func testAllCases() {
        let cases = ColorSchemePreference.allCases
        XCTAssertEqual(cases.count, 3)
    }

    func testDisplayName() {
        for pref in ColorSchemePreference.allCases {
            XCTAssertFalse(pref.displayName.isEmpty)
        }
    }
}

// MARK: - ThemeManager Tests

@MainActor
final class ThemeManagerTests: XCTestCase {

    func testInit() {
        let manager = ThemeManager()
        XCTAssertNotNil(manager)
    }

    func testSetTheme() {
        let manager = ThemeManager()
        manager.setTheme(.dark)
        XCTAssertEqual(manager.currentTheme.id, "dark")
    }

    func testSetColorScheme() {
        let manager = ThemeManager()
        manager.setColorScheme(.dark)
        XCTAssertTrue(manager.isDarkMode)
    }

    func testAutoMode() {
        let manager = ThemeManager()
        manager.setColorScheme(.auto)
        XCTAssertTrue(manager.isAutoMode)
    }

    func testReset() {
        let manager = ThemeManager()
        manager.setTheme(.dark)
        manager.reset()
        XCTAssertEqual(manager.currentTheme.id, "default")
    }

    func testAvailableThemes() {
        let manager = ThemeManager()
        XCTAssertGreaterThan(manager.availableThemes.count, 0)
    }

    func testLoadCustomTheme() {
        let manager = ThemeManager()
        let custom = Theme.custom(id: "test", name: "Test", palette: .default)
        manager.loadCustomTheme(custom)
        XCTAssertEqual(manager.currentTheme.id, "test")
    }
}

// MARK: - String Extension Tests

final class StringAccessibilityTests: XCTestCase {

    func testAsAccessibilityIdentifier() {
        let id = "my_button".asAccessibilityIdentifier
        XCTAssertEqual(id.id, "my_button")
    }
}

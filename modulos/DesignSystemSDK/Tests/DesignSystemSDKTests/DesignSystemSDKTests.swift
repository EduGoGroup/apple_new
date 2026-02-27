import Testing
@testable import DesignSystemSDK

// MARK: - Theme Tests

@Suite struct ThemeTests {

    @Test func testDefaultTheme() {
        let theme = Theme.default
        #expect(theme.id == "default")
        #expect(theme.name == "Default")
    }

    @Test func testDarkTheme() {
        let theme = Theme.dark
        #expect(theme.id == "dark")
    }

    @Test func testHighContrastTheme() {
        let theme = Theme.highContrast
        #expect(theme.id == "highContrast")
    }

    @Test func testGrayscaleTheme() {
        let theme = Theme.grayscale
        #expect(theme.id == "grayscale")
    }

    @Test func testCustomTheme() {
        let custom = Theme.custom(
            id: "myTheme",
            name: "My Theme",
            palette: .default
        )
        #expect(custom.id == "myTheme")
        #expect(custom.name == "My Theme")
    }

    @Test func testThemeEquality() {
        let a = Theme.default
        let b = Theme.default
        #expect(a == b)
        #expect(Theme.default != Theme.dark)
    }
}

// MARK: - Typography Tests

@Suite struct TypographyTests {

    @Test func testDefaultTypography() {
        let typo = Typography.default
        #expect(!typo.fontFamily.isEmpty)
        #expect(typo.baseSize > 0)
    }

    @Test func testCompactTypography() {
        let compact = Typography.compact
        let def = Typography.default
        #expect(compact.baseSize <= def.baseSize)
    }

    @Test func testLargeTypography() {
        let large = Typography.large
        let def = Typography.default
        #expect(large.baseSize >= def.baseSize)
    }
}

// MARK: - Spacing Tests

@Suite struct SpacingTests {

    @Test func testDefaultSpacing() {
        let spacing = Spacing.default
        #expect(spacing.md > 0)
    }

    @Test func testCompactSpacing() {
        let compact = Spacing.compact
        let def = Spacing.default
        #expect(compact.md <= def.md)
    }

    @Test func testGenerousSpacing() {
        let generous = Spacing.generous
        let def = Spacing.default
        #expect(generous.md >= def.md)
    }
}

// MARK: - CornerRadius Tests

@Suite struct CornerRadiusTests {

    @Test func testDefaultCornerRadius() {
        let cr = CornerRadius.default
        #expect(cr.md > 0)
    }

    @Test func testSquareCornerRadius() {
        let square = CornerRadius.square
        #expect(square.sm == 0)
    }

    @Test func testSoftCornerRadius() {
        let soft = CornerRadius.soft
        let def = CornerRadius.default
        #expect(soft.md >= def.md)
    }
}

// MARK: - Shadows Tests

@Suite struct ShadowsTests {

    @Test func testDefaultShadows() {
        let shadows = Shadows.default
        #expect(shadows.md != nil)
    }
}

// MARK: - ColorPalette Tests

@Suite struct ColorPaletteTests {

    @Test func testDefaultPalette() {
        let palette = ColorPalette.default
        #expect(palette.primary != nil)
        #expect(palette.secondary != nil)
        #expect(palette.error != nil)
    }

    @Test func testHighContrastPalette() {
        let palette = ColorPalette.highContrast
        #expect(palette.primary != nil)
    }

    @Test func testGrayscalePalette() {
        let palette = ColorPalette.grayscale
        #expect(palette.primary != nil)
    }
}

// MARK: - ColorToken Tests

@Suite struct ColorTokenTests {

    @Test func testColorTokenResolveLight() {
        let token = ColorToken(light: .white, dark: .black)
        let resolved = token.resolve(for: .light)
        #expect(resolved == .white)
    }

    @Test func testColorTokenResolveDark() {
        let token = ColorToken(light: .white, dark: .black)
        let resolved = token.resolve(for: .dark)
        #expect(resolved == .black)
    }
}

// MARK: - AccessibilityIdentifier Tests

@Suite struct AccessibilityIdentifierTests {

    @Test func testButtonIdentifier() {
        let id = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        #expect(id.id == "auth_login_button_submit")
    }

    @Test func testTextFieldIdentifier() {
        let id = AccessibilityIdentifier.textField(module: "auth", screen: "login", field: "email")
        #expect(id.id == "auth_login_textfield_email")
    }

    @Test func testToggleIdentifier() {
        let id = AccessibilityIdentifier.toggle(module: "settings", screen: "main", setting: "dark")
        #expect(id.id == "settings_main_toggle_dark")
    }

    @Test func testLinkIdentifier() {
        let id = AccessibilityIdentifier.link(module: "nav", screen: "home", destination: "profile")
        #expect(id.id == "nav_home_link_profile")
    }

    @Test func testTabIdentifier() {
        let id = AccessibilityIdentifier.tab(module: "nav", name: "home")
        #expect(id.id == "nav_tab_home")
    }

    @Test func testCellIdentifier() {
        let id = AccessibilityIdentifier.cell(module: "list", screen: "users", index: 0)
        #expect(id.id == "list_users_cell_0")
    }

    @Test func testCustomIdentifier() {
        let id = AccessibilityIdentifier.custom("my_custom_id")
        #expect(id.id == "my_custom_id")
    }

    @Test func testEquality() {
        let a = AccessibilityIdentifier.custom("test")
        let b = AccessibilityIdentifier.custom("test")
        #expect(a == b)
    }

    @Test func testIsValid() {
        let valid = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        #expect(valid.isValid)

        let invalid = AccessibilityIdentifier.custom("")
        #expect(!invalid.isValid)
    }

    @Test func testComponents() {
        let id = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        #expect(id.components == ["auth", "login", "button", "submit"])
    }

    @Test func testModule() {
        let id = AccessibilityIdentifier.button(module: "auth", screen: "login", action: "submit")
        #expect(id.module == "auth")
    }
}

// MARK: - AccessibilityIdentifierBuilder Tests

@Suite struct AccessibilityIdentifierBuilderTests {

    @Test func testBuilderFlow() {
        let id = AccessibilityIdentifierBuilder()
            .module("auth")
            .screen("login")
            .component("button")
            .descriptor("submit")
            .build()
        #expect(id.id == "auth_login_button_submit")
    }

    @Test func testBuilderWithIndex() {
        let id = AccessibilityIdentifierBuilder()
            .module("list")
            .screen("users")
            .component("cell")
            .index(3)
            .build()
        #expect(id.id == "list_users_cell_3")
    }
}

// MARK: - AccessibilityIdentifier Registry Tests

@MainActor @Suite struct AccessibilityIdentifierRegistryTests {

    init() {
        AccessibilityIdentifierRegistry.shared.reset()
    }

    @Test func testRegisterAndCheck() {
        let id = AccessibilityIdentifier.custom("test_register")
        let registry = AccessibilityIdentifierRegistry.shared
        let registered = registry.register(id)
        #expect(registered)
        #expect(registry.isRegistered(id))
    }

    @Test func testDuplicateRegister() {
        let id = AccessibilityIdentifier.custom("test_dup")
        let registry = AccessibilityIdentifierRegistry.shared
        _ = registry.register(id)
        let second = registry.register(id)
        #expect(!second)
    }

    @Test func testReset() {
        let id = AccessibilityIdentifier.custom("test_reset")
        let registry = AccessibilityIdentifierRegistry.shared
        _ = registry.register(id)
        registry.reset()
        #expect(!registry.isRegistered(id))
    }

    @Test func testAllIdentifiers() {
        let registry = AccessibilityIdentifierRegistry.shared
        registry.reset()
        _ = registry.register(AccessibilityIdentifier.custom("z_last"))
        _ = registry.register(AccessibilityIdentifier.custom("a_first"))
        let all = registry.allIdentifiers
        #expect(all == ["a_first", "z_last"])
    }
}

// MARK: - EduShadowLevel Tests

@Suite struct EduShadowLevelTests {

    @Test func testAllCases() {
        #expect(EduShadowLevel.allCases.count > 0)
    }

    @Test func testConfigurationNotNil() {
        for level in EduShadowLevel.allCases {
            let config = level.configuration
            #expect(config.radius >= 0)
        }
    }
}

// MARK: - EduShadowConfiguration Tests

@Suite struct EduShadowConfigurationTests {

    @Test func testInit() {
        let config = EduShadowConfiguration(color: .black, radius: 4, x: 0, y: 2)
        #expect(config.radius == 4)
        #expect(config.x == 0)
        #expect(config.y == 2)
    }

    @Test func testEquality() {
        let a = EduShadowConfiguration(color: .black, radius: 4, x: 0, y: 2)
        let b = EduShadowConfiguration(color: .black, radius: 4, x: 0, y: 2)
        #expect(a == b)
    }
}

// MARK: - EduLiquidRoundedRectangle Tests

@Suite struct EduLiquidRoundedRectangleTests {

    @Test func testInit() {
        let shape = EduLiquidRoundedRectangle(cornerRadius: 16, smoothness: 0.6)
        #expect(shape.cornerRadius == 16)
        #expect(shape.smoothness == 0.6)
    }

    @Test func testDefaultInit() {
        let shape = EduLiquidRoundedRectangle()
        #expect(shape.cornerRadius == 16)
        #expect(shape.smoothness == 0.6)
    }
}

// MARK: - EduMorphableShape Tests

@Suite struct EduMorphableShapeTests {

    @Test func testCornerFactor() {
        #expect(EduMorphableShape.circle.cornerFactor == .infinity)
        #expect(EduMorphableShape.rectangle.cornerFactor == 0)
    }
}

// MARK: - ScalingMetrics Tests

@Suite struct ScalingMetricsEnvironmentTests {

    @Test func testDefaultSizeCategory() {
        let env = ScalingMetricsEnvironment()
        #expect(env.sizeCategory == .large)
    }

    @Test func testSpacingValues() {
        let env = ScalingMetricsEnvironment()
        #expect(env.spacingXS > 0)
        #expect(env.spacingSM > 0)
        #expect(env.spacingMD > 0)
        #expect(env.spacingLG > 0)
    }

    @Test func testSpacingOrdering() {
        let env = ScalingMetricsEnvironment()
        #expect(env.spacingXS < env.spacingSM)
        #expect(env.spacingSM < env.spacingMD)
        #expect(env.spacingMD < env.spacingLG)
    }
}

// MARK: - ColorSchemePreference Tests

@MainActor @Suite struct ColorSchemePreferenceTests {

    @Test func testAllCases() {
        let cases = ColorSchemePreference.allCases
        #expect(cases.count == 3)
    }

    @Test func testDisplayName() {
        for pref in ColorSchemePreference.allCases {
            #expect(!pref.displayName.isEmpty)
        }
    }
}

// MARK: - ThemeManager Tests

@MainActor @Suite struct ThemeManagerTests {

    @Test func testInit() {
        let manager = ThemeManager()
        #expect(manager != nil)
    }

    @Test func testSetTheme() {
        let manager = ThemeManager()
        manager.setTheme(.dark)
        #expect(manager.currentTheme.id == "dark")
    }

    @Test func testSetColorScheme() {
        let manager = ThemeManager()
        manager.setColorScheme(.dark)
        #expect(manager.isDarkMode)
    }

    @Test func testAutoMode() {
        let manager = ThemeManager()
        manager.setColorScheme(.auto)
        #expect(manager.isAutoMode)
    }

    @Test func testReset() {
        let manager = ThemeManager()
        manager.setTheme(.dark)
        manager.reset()
        #expect(manager.currentTheme.id == "default")
    }

    @Test func testAvailableThemes() {
        let manager = ThemeManager()
        #expect(manager.availableThemes.count > 0)
    }

    @Test func testLoadCustomTheme() {
        let manager = ThemeManager()
        let custom = Theme.custom(id: "test", name: "Test", palette: .default)
        manager.loadCustomTheme(custom)
        #expect(manager.currentTheme.id == "test")
    }
}

// MARK: - String Extension Tests

@Suite struct StringAccessibilityTests {

    @Test func testAsAccessibilityIdentifier() {
        let id = "my_button".asAccessibilityIdentifier
        #expect(id.id == "my_button")
    }
}

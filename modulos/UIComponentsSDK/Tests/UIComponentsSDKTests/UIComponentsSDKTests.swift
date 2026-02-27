import Testing
@testable import UIComponentsSDK

// MARK: - ViewState Tests

@Suite struct ViewStateTests {

    @Test func testLoading() {
        let state: ViewState<String> = .loading
        if case .loading = state {
            // pass
        } else {
            Issue.record("Expected loading state")
        }
    }

    @Test func testSuccess() {
        let state: ViewState<String> = .success("data")
        if case .success(let value) = state {
            #expect(value == "data")
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test func testEmpty() {
        let state: ViewState<String> = .empty
        if case .empty = state {
            // pass
        } else {
            Issue.record("Expected empty state")
        }
    }

    @Test func testError() {
        let state: ViewState<String> = .error("Something went wrong")
        if case .error(let msg) = state {
            #expect(msg == "Something went wrong")
        } else {
            Issue.record("Expected error state")
        }
    }
}

// MARK: - DesignTokens Tests

@Suite struct DesignTokensSpacingTests {

    @Test func testSpacingValues() {
        #expect(DesignTokens.Spacing.xs == 4)
        #expect(DesignTokens.Spacing.small == 8)
        #expect(DesignTokens.Spacing.medium == 12)
        #expect(DesignTokens.Spacing.large == 16)
        #expect(DesignTokens.Spacing.xl == 20)
        #expect(DesignTokens.Spacing.xxl == 24)
    }

    @Test func testSpacingOrdering() {
        #expect(DesignTokens.Spacing.xs < DesignTokens.Spacing.small)
        #expect(DesignTokens.Spacing.small < DesignTokens.Spacing.medium)
        #expect(DesignTokens.Spacing.medium < DesignTokens.Spacing.large)
        #expect(DesignTokens.Spacing.large < DesignTokens.Spacing.xl)
        #expect(DesignTokens.Spacing.xl < DesignTokens.Spacing.xxl)
    }
}

@Suite struct DesignTokensCornerRadiusTests {

    @Test func testCornerRadiusValues() {
        #expect(DesignTokens.CornerRadius.small == 6)
        #expect(DesignTokens.CornerRadius.medium == 8)
        #expect(DesignTokens.CornerRadius.large == 10)
        #expect(DesignTokens.CornerRadius.xl == 12)
    }

    @Test func testCornerRadiusOrdering() {
        #expect(DesignTokens.CornerRadius.small < DesignTokens.CornerRadius.medium)
        #expect(DesignTokens.CornerRadius.medium < DesignTokens.CornerRadius.large)
        #expect(DesignTokens.CornerRadius.large < DesignTokens.CornerRadius.xl)
    }
}

@Suite struct DesignTokensShadowTests {

    @Test func testShadowNone() {
        #expect(DesignTokens.Shadow.none == 0)
    }
}

// MARK: - PreviewMocks Tests

@MainActor
@Suite struct PreviewMocksTests {

    @Test func testStrings() {
        #expect(!PreviewMocks.shortText.isEmpty)
        #expect(!PreviewMocks.mediumText.isEmpty)
        #expect(!PreviewMocks.longText.isEmpty)
        #expect(!PreviewMocks.loremIpsum.isEmpty)
    }

    @Test func testUserData() {
        #expect(!PreviewMocks.userName.isEmpty)
        #expect(!PreviewMocks.userEmail.isEmpty)
    }

    @Test func testLists() {
        #expect(PreviewMocks.shortList.count == 3)
        #expect(PreviewMocks.mediumList.count == 10)
        #expect(PreviewMocks.longList.count == 50)
    }
}

// MARK: - ToastStyle Tests

@Suite struct ToastStyleTests {

    @Test func testCases() {
        let success = ToastStyle.success
        let error = ToastStyle.error
        let warning = ToastStyle.warning
        let info = ToastStyle.info
        // Verify they are distinct
        #expect(!("\(success)" == "\(error)"))
        #expect(!("\(warning)" == "\(info)"))
    }
}

// MARK: - ToastItem Tests

@Suite struct ToastItemTests {

    @Test func testInit() {
        let item = ToastItem(message: "Hello", style: .success, duration: 3.0)
        #expect(item.id != nil)
    }
}

// MARK: - BannerItem Tests

@Suite struct BannerItemTests {

    @Test func testInit() {
        let item = BannerItem(message: "Banner msg", style: .info, onDismiss: nil)
        #expect(item.id != nil)
    }
}

// MARK: - EduBreadcrumbItem Tests

@MainActor
@Suite struct EduBreadcrumbItemTests {

    @Test func testInit() {
        let item = EduBreadcrumbItem(id: "home", title: "Home")
        #expect(item.title == "Home")
        #expect(item.id == "home")
        #expect(item.icon == nil)
        #expect(item.destination == nil)
    }

    @Test func testInitWithAllParams() {
        let item = EduBreadcrumbItem(id: "settings", title: "Settings", icon: "gear", destination: "settings")
        #expect(item.icon == "gear")
        #expect(item.destination == "settings")
    }
}

// MARK: - EduBreadcrumbBuilder Tests

@MainActor
@Suite struct EduBreadcrumbBuilderTests {

    @Test func testBuild() {
        var builder = EduBreadcrumbBuilder()
        builder.add(id: "home", title: "Home")
        builder.add(id: "settings", title: "Settings")
        builder.add(id: "profile", title: "Profile")
        let items = builder.build()
        #expect(items.count == 3)
        #expect(items[0].title == "Home")
        #expect(items[2].title == "Profile")
    }

    @Test func testFromPath() {
        let items = EduBreadcrumbBuilder.fromPath(
            ["home", "settings"],
            titles: ["home": "Home", "settings": "Settings"]
        )
        #expect(items.count == 2)
        #expect(items[0].title == "Home")
    }
}

// MARK: - SwipeAction Tests

@Suite struct SwipeActionTests {

    @Test func testInit() {
        let action = SwipeAction(
            title: "Delete",
            icon: "trash",
            role: .destructive,
            action: {}
        )
        #expect(action.title == "Delete")
        #expect(action.icon == "trash")
    }
}

// MARK: - SwipeActionRole Tests

@Suite struct SwipeActionRoleTests {

    @Test func testCases() {
        let destructive = SwipeActionRole.destructive
        let normal = SwipeActionRole.normal
        #expect(!("\(destructive)" == "\(normal)"))
    }
}

// MARK: - EduSkeletonShape Tests

@Suite struct EduSkeletonShapeTests {

    @Test func testCases() {
        let rect = EduSkeletonShape.rectangle
        let circle = EduSkeletonShape.circle
        let rounded = EduSkeletonShape.roundedRectangle(8)
        let capsule = EduSkeletonShape.capsule
        #expect(!("\(rect)" == "\(circle)"))
        #expect(!("\(circle)" == "\(rounded)"))
        _ = capsule
    }
}

// MARK: - EduActivityIndicatorStyle Tests

@Suite struct EduActivityIndicatorStyleTests {

    @Test func testCases() {
        let small = EduActivityIndicatorStyle.small
        let medium = EduActivityIndicatorStyle.medium
        let large = EduActivityIndicatorStyle.large
        #expect(!("\(small)" == "\(large)"))
        _ = medium // ensure it exists
    }
}

// MARK: - EduProgressBarMode Tests

@Suite struct EduProgressBarModeTests {

    @Test func testCases() {
        let determinate = EduProgressBarMode.determinate(0.5)
        let indeterminate = EduProgressBarMode.indeterminate
        #expect(!("\(determinate)" == "\(indeterminate)"))
    }
}

// MARK: - EduNavigationBarConfiguration Tests

@MainActor
@Suite struct EduNavigationBarConfigurationTests {

    @Test func testDefaultInit() {
        let config = EduNavigationBarConfiguration()
        #expect(config.showsBackButton)
        #expect(!config.showsLeadingButton)
        #expect(!config.showsTrailingButton)
    }

    @Test func testCustomInit() {
        let config = EduNavigationBarConfiguration(
            displayMode: .large,
            showsBackButton: false
        )
        #expect(!config.showsBackButton)
    }
}

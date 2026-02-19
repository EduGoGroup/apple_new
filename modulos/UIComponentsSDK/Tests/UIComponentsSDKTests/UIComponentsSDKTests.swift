import XCTest
@testable import UIComponentsSDK

// MARK: - ViewState Tests

final class ViewStateTests: XCTestCase {

    func testLoading() {
        let state: ViewState<String> = .loading
        if case .loading = state {
            // pass
        } else {
            XCTFail("Expected loading state")
        }
    }

    func testSuccess() {
        let state: ViewState<String> = .success("data")
        if case .success(let value) = state {
            XCTAssertEqual(value, "data")
        } else {
            XCTFail("Expected success state")
        }
    }

    func testEmpty() {
        let state: ViewState<String> = .empty
        if case .empty = state {
            // pass
        } else {
            XCTFail("Expected empty state")
        }
    }

    func testError() {
        let state: ViewState<String> = .error("Something went wrong")
        if case .error(let msg) = state {
            XCTAssertEqual(msg, "Something went wrong")
        } else {
            XCTFail("Expected error state")
        }
    }
}

// MARK: - DesignTokens Tests

final class DesignTokensSpacingTests: XCTestCase {

    func testSpacingValues() {
        XCTAssertEqual(DesignTokens.Spacing.xs, 4)
        XCTAssertEqual(DesignTokens.Spacing.small, 8)
        XCTAssertEqual(DesignTokens.Spacing.medium, 12)
        XCTAssertEqual(DesignTokens.Spacing.large, 16)
        XCTAssertEqual(DesignTokens.Spacing.xl, 20)
        XCTAssertEqual(DesignTokens.Spacing.xxl, 24)
    }

    func testSpacingOrdering() {
        XCTAssertLessThan(DesignTokens.Spacing.xs, DesignTokens.Spacing.small)
        XCTAssertLessThan(DesignTokens.Spacing.small, DesignTokens.Spacing.medium)
        XCTAssertLessThan(DesignTokens.Spacing.medium, DesignTokens.Spacing.large)
        XCTAssertLessThan(DesignTokens.Spacing.large, DesignTokens.Spacing.xl)
        XCTAssertLessThan(DesignTokens.Spacing.xl, DesignTokens.Spacing.xxl)
    }
}

final class DesignTokensCornerRadiusTests: XCTestCase {

    func testCornerRadiusValues() {
        XCTAssertEqual(DesignTokens.CornerRadius.small, 6)
        XCTAssertEqual(DesignTokens.CornerRadius.medium, 8)
        XCTAssertEqual(DesignTokens.CornerRadius.large, 10)
        XCTAssertEqual(DesignTokens.CornerRadius.xl, 12)
    }

    func testCornerRadiusOrdering() {
        XCTAssertLessThan(DesignTokens.CornerRadius.small, DesignTokens.CornerRadius.medium)
        XCTAssertLessThan(DesignTokens.CornerRadius.medium, DesignTokens.CornerRadius.large)
        XCTAssertLessThan(DesignTokens.CornerRadius.large, DesignTokens.CornerRadius.xl)
    }
}

final class DesignTokensShadowTests: XCTestCase {

    func testShadowNone() {
        XCTAssertEqual(DesignTokens.Shadow.none, 0)
    }
}

// MARK: - PreviewMocks Tests

@MainActor
final class PreviewMocksTests: XCTestCase {

    func testStrings() {
        XCTAssertFalse(PreviewMocks.shortText.isEmpty)
        XCTAssertFalse(PreviewMocks.mediumText.isEmpty)
        XCTAssertFalse(PreviewMocks.longText.isEmpty)
        XCTAssertFalse(PreviewMocks.loremIpsum.isEmpty)
    }

    func testUserData() {
        XCTAssertFalse(PreviewMocks.userName.isEmpty)
        XCTAssertFalse(PreviewMocks.userEmail.isEmpty)
    }

    func testLists() {
        XCTAssertEqual(PreviewMocks.shortList.count, 3)
        XCTAssertEqual(PreviewMocks.mediumList.count, 10)
        XCTAssertEqual(PreviewMocks.longList.count, 50)
    }
}

// MARK: - ToastStyle Tests

final class ToastStyleTests: XCTestCase {

    func testCases() {
        let success = ToastStyle.success
        let error = ToastStyle.error
        let warning = ToastStyle.warning
        let info = ToastStyle.info
        // Verify they are distinct
        XCTAssertFalse("\(success)" == "\(error)")
        XCTAssertFalse("\(warning)" == "\(info)")
    }
}

// MARK: - ToastItem Tests

final class ToastItemTests: XCTestCase {

    func testInit() {
        let item = ToastItem(message: "Hello", style: .success, duration: 3.0)
        XCTAssertNotNil(item.id)
    }
}

// MARK: - BannerItem Tests

final class BannerItemTests: XCTestCase {

    func testInit() {
        let item = BannerItem(message: "Banner msg", style: .info, onDismiss: nil)
        XCTAssertNotNil(item.id)
    }
}

// MARK: - EduBreadcrumbItem Tests

@MainActor
final class EduBreadcrumbItemTests: XCTestCase {

    func testInit() {
        let item = EduBreadcrumbItem(id: "home", title: "Home")
        XCTAssertEqual(item.title, "Home")
        XCTAssertEqual(item.id, "home")
        XCTAssertNil(item.icon)
        XCTAssertNil(item.destination)
    }

    func testInitWithAllParams() {
        let item = EduBreadcrumbItem(id: "settings", title: "Settings", icon: "gear", destination: "settings")
        XCTAssertEqual(item.icon, "gear")
        XCTAssertEqual(item.destination, "settings")
    }
}

// MARK: - EduBreadcrumbBuilder Tests

@MainActor
final class EduBreadcrumbBuilderTests: XCTestCase {

    func testBuild() {
        var builder = EduBreadcrumbBuilder()
        builder.add(id: "home", title: "Home")
        builder.add(id: "settings", title: "Settings")
        builder.add(id: "profile", title: "Profile")
        let items = builder.build()
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].title, "Home")
        XCTAssertEqual(items[2].title, "Profile")
    }

    func testFromPath() {
        let items = EduBreadcrumbBuilder.fromPath(
            ["home", "settings"],
            titles: ["home": "Home", "settings": "Settings"]
        )
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Home")
    }
}

// MARK: - SwipeAction Tests

@available(macOS 26.0, iOS 26.0, *)
final class SwipeActionTests: XCTestCase {

    func testInit() {
        let action = SwipeAction(
            title: "Delete",
            icon: "trash",
            role: .destructive,
            action: {}
        )
        XCTAssertEqual(action.title, "Delete")
        XCTAssertEqual(action.icon, "trash")
    }
}

// MARK: - SwipeActionRole Tests

@available(macOS 26.0, iOS 26.0, *)
final class SwipeActionRoleTests: XCTestCase {

    func testCases() {
        let destructive = SwipeActionRole.destructive
        let normal = SwipeActionRole.normal
        XCTAssertFalse("\(destructive)" == "\(normal)")
    }
}

// MARK: - EduSkeletonShape Tests

final class EduSkeletonShapeTests: XCTestCase {

    func testCases() {
        let rect = EduSkeletonShape.rectangle
        let circle = EduSkeletonShape.circle
        let rounded = EduSkeletonShape.roundedRectangle(8)
        let capsule = EduSkeletonShape.capsule
        XCTAssertFalse("\(rect)" == "\(circle)")
        XCTAssertFalse("\(circle)" == "\(rounded)")
        _ = capsule
    }
}

// MARK: - EduActivityIndicatorStyle Tests

final class EduActivityIndicatorStyleTests: XCTestCase {

    func testCases() {
        let small = EduActivityIndicatorStyle.small
        let medium = EduActivityIndicatorStyle.medium
        let large = EduActivityIndicatorStyle.large
        XCTAssertFalse("\(small)" == "\(large)")
        _ = medium // ensure it exists
    }
}

// MARK: - EduProgressBarMode Tests

final class EduProgressBarModeTests: XCTestCase {

    func testCases() {
        let determinate = EduProgressBarMode.determinate(0.5)
        let indeterminate = EduProgressBarMode.indeterminate
        XCTAssertFalse("\(determinate)" == "\(indeterminate)")
    }
}

// MARK: - EduNavigationBarConfiguration Tests

@MainActor
final class EduNavigationBarConfigurationTests: XCTestCase {

    func testDefaultInit() {
        let config = EduNavigationBarConfiguration()
        XCTAssertTrue(config.showsBackButton)
        XCTAssertFalse(config.showsLeadingButton)
        XCTAssertFalse(config.showsTrailingButton)
    }

    func testCustomInit() {
        let config = EduNavigationBarConfiguration(
            displayMode: .large,
            showsBackButton: false
        )
        XCTAssertFalse(config.showsBackButton)
    }
}

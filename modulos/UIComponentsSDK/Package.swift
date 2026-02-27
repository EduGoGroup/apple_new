// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "UIComponentsSDK",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "UIComponentsSDK", targets: ["UIComponentsSDK"])
    ],
    dependencies: [
        .package(path: "../DesignSystemSDK"),
        .package(path: "../FormsSDK")
    ],
    targets: [
        .target(
            name: "UIComponentsSDK",
            dependencies: ["DesignSystemSDK", "FormsSDK"],
            path: "Sources/UIComponentsSDK"
        ),
        .testTarget(
            name: "UIComponentsSDKTests",
            dependencies: ["UIComponentsSDK"],
            path: "Tests/UIComponentsSDKTests"
        )
    ]
)

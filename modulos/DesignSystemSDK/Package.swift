// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DesignSystemSDK",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "DesignSystemSDK", targets: ["DesignSystemSDK"])
    ],
    targets: [
        .target(
            name: "DesignSystemSDK",
            path: "Sources/DesignSystemSDK"
        ),
        .testTarget(
            name: "DesignSystemSDKTests",
            dependencies: ["DesignSystemSDK"],
            path: "Tests/DesignSystemSDKTests"
        )
    ]
)

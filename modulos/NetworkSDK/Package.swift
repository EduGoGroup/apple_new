// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NetworkSDK",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "NetworkSDK", targets: ["NetworkSDK"])
    ],
    dependencies: [
        .package(path: "../FoundationToolkit")
    ],
    targets: [
        .target(
            name: "NetworkSDK",
            dependencies: ["FoundationToolkit"],
            path: "Sources/NetworkSDK"
        ),
        .testTarget(
            name: "NetworkSDKTests",
            dependencies: ["NetworkSDK"],
            path: "Tests/NetworkSDKTests"
        )
    ]
)

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FormsSDK",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "FormsSDK", targets: ["FormsSDK"])
    ],
    targets: [
        .target(
            name: "FormsSDK",
            path: "Sources/FormsSDK"
        ),
        .testTarget(
            name: "FormsSDKTests",
            dependencies: ["FormsSDK"],
            path: "Tests/FormsSDKTests"
        )
    ]
)

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LoggerSDK",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "LoggerSDK",
            targets: ["LoggerSDK"]
        )
    ],
    targets: [
        .target(
            name: "LoggerSDK",
            path: "Sources/LoggerSDK"
        ),
        .testTarget(
            name: "LoggerSDKTests",
            dependencies: ["LoggerSDK"],
            path: "Tests/LoggerSDKTests"
        )
    ]
)

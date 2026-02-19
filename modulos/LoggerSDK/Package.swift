// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LoggerSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
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
            path: "Sources/LoggerSDK",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "LoggerSDKTests",
            dependencies: ["LoggerSDK"],
            path: "Tests/LoggerSDKTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)

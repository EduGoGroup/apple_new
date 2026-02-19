// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CQRSKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "CQRSKit",
            targets: ["CQRSKit"]
        )
    ],
    targets: [
        .target(
            name: "CQRSKit",
            path: "Sources/CQRSKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "CQRSKitTests",
            dependencies: ["CQRSKit"],
            path: "Tests/CQRSKitTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduPresentation",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "EduPresentation", targets: ["EduPresentation"])
    ],
    dependencies: [
        .package(path: "../Foundation"),
        .package(path: "../Core"),
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "EduPresentation",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core"),
                .product(name: "EduDomain", package: "Domain")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EduPresentationTests",
            dependencies: [
                "EduPresentation",
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core"),
                .product(name: "EduDomain", package: "Domain")
            ],
            path: "Tests"
        )
    ]
)

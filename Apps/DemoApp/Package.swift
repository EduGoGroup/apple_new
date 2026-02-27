// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DemoApp",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    dependencies: [
        .package(path: "../../Packages/Core"),
        .package(path: "../../Packages/Infrastructure"),
        .package(path: "../../Packages/Domain"),
        .package(path: "../../Packages/Presentation"),
        .package(path: "../../Packages/Features"),
        .package(path: "../../Packages/DynamicUI")
    ],
    targets: [
        .executableTarget(
            name: "DemoApp",
            dependencies: [
                .product(name: "EduPresentation", package: "Presentation"),
                .product(name: "EduFeatures", package: "Features"),
                .product(name: "EduDynamicUI", package: "DynamicUI"),
                .product(name: "EduNetwork", package: "Infrastructure"),
                .product(name: "EduStorage", package: "Infrastructure"),
                .product(name: "EduCore", package: "Core"),
                .product(name: "EduDomain", package: "Domain")
            ],
            path: "Sources"
        )
    ]
)

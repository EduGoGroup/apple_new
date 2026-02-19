// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DemoApp",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    dependencies: [
        .package(path: "../../Packages/Foundation"),
        .package(path: "../../Packages/Core"),
        .package(path: "../../Packages/Infrastructure"),
        .package(path: "../../Packages/Domain"),
        .package(path: "../../Packages/Presentation"),
        .package(path: "../../Packages/Features")
    ],
    targets: [
        .executableTarget(
            name: "DemoApp",
            dependencies: [
                .product(name: "EduPresentation", package: "Presentation"),
                .product(name: "EduFeatures", package: "Features")
            ],
            path: "Sources"
        )
    ]
)

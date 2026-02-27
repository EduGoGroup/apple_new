// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EduFeatures",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "EduFeatures", targets: ["EduFeatures"])
    ],
    dependencies: [
        .package(path: "../Foundation"),
        .package(path: "../Core"),
        .package(path: "../Infrastructure"),
        .package(path: "../Domain"),
        .package(path: "../Presentation")
    ],
    targets: [
        .target(
            name: "EduFeatures",
            dependencies: [
                .product(name: "EduFoundation", package: "Foundation"),
                .product(name: "EduCore", package: "Core"),
                .product(name: "EduInfrastructure", package: "Infrastructure"),
                .product(name: "EduDomain", package: "Domain"),
                .product(name: "EduPresentation", package: "Presentation")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EduFeaturesTests",
            dependencies: ["EduFeatures"],
            path: "Tests/FeaturesTests"
        )
    ]
)

// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ARCL",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ARCL",
            targets: ["ARKit-CoreLocation"]
        )
    ],
    targets: [
        .target(
            name: "ARKit-CoreLocation",
            dependencies: [],
            path: "Sources/ARKit-CoreLocation",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ARCLTests",
            dependencies: ["ARKit-CoreLocation"],
            path: "ARCLTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)

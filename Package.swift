// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EssentialNetwork",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "EssentialNetwork",
            targets: ["EssentialNetwork"]
        ),
        .library(
            name: "EssentialNetworkTesting",
            targets: ["EssentialNetworkTesting"]
        )
    ],
    targets: [
        .target(
            name: "EssentialNetwork",
            path: "Sources"
        ),
        .target(
            name: "EssentialNetworkTesting",
            dependencies: ["EssentialNetwork"],
            path: "Testing"
        ),
        .testTarget(
            name: "EssentialNetworkTests",
            dependencies: ["EssentialNetwork", "EssentialNetworkTesting"],
            path: "Tests"
        )
    ]
)

// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamUtilities",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
        .macCatalyst(.v16),
        .tvOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "StreamUtilities",
            targets: ["StreamUtilities", "SyncStream", "BidirectionalStream"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/rockmagma02/swift-docc-plugin", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "StreamUtilities",
            dependencies: ["SyncStream", "BidirectionalStream"]
        ),
        .target(
            name: "SyncStream"
        ),
        .target(
            name: "BidirectionalStream",
            dependencies: ["SyncStream"]
        ),
        .testTarget(
            name: "SyncStreamTests",
            dependencies: ["SyncStream"]
        ),
        .testTarget(
            name: "BidirectionalStreamTests",
            dependencies: ["BidirectionalStream"]
        ),
    ]
)

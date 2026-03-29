// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_localization",
    platforms: [
        .macOS("10.15"),
    ],
    products: [
        .library(name: "flutter-localization", targets: ["flutter_localization"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_localization",
            dependencies: [],
            resources: [],
        ),
    ],
)

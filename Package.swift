// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ArcadeAudioKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v12),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "ArcadeAudioKit",
            targets: ["ArcadeAudioKit"]
        ),
    ],
    targets: [
        .target(
            name: "ArcadeAudioKit",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "ArcadeAudioKitTests",
            dependencies: ["ArcadeAudioKit"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

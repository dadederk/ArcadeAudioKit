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
        .executable(
            name: "render-audio-recipe",
            targets: ["RenderAudioRecipe"]
        ),
    ],
    targets: [
        .target(
            name: "ArcadeAudioKit",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .executableTarget(
            name: "RenderAudioRecipe",
            dependencies: ["ArcadeAudioKit"],
            path: "Tools/RenderAudioRecipe",
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

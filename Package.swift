// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ThinkingOrbsKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ThinkingOrbsKit", targets: ["ThinkingOrbsKit"]),
        .executable(name: "ThinkingOrbsSnapshot", targets: ["ThinkingOrbsSnapshot"])
    ],
    targets: [
        .target(
            name: "ThinkingOrbsKit",
            path: "ports/ios/ThinkingOrbsKit/Sources/ThinkingOrbsKit"
        ),
        .testTarget(
            name: "ThinkingOrbsKitTests",
            dependencies: ["ThinkingOrbsKit"],
            path: "ports/ios/ThinkingOrbsKit/Tests/ThinkingOrbsKitTests",
            resources: [.copy("Fixtures")]
        ),
        .executableTarget(
            name: "ThinkingOrbsSnapshot",
            dependencies: ["ThinkingOrbsKit"],
            path: "ports/ios/ThinkingOrbsKit/Sources/ThinkingOrbsSnapshot"
        )
    ]
)

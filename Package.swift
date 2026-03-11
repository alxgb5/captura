// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Captura",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CapturaCore",
            targets: ["CapturaCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CapturaCore",
            path: "Sources/CapturaCore",
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "CapturaTests",
            dependencies: ["CapturaCore"],
            path: "Tests/CapturaTests"
        )
    ]
)

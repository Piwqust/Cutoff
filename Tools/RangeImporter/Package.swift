// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RangeImporter",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "RangeImporter",
            path: "Sources/RangeImporter"
        ),
        .testTarget(
            name: "RangeImporterTests",
            dependencies: ["RangeImporter"],
            path: "Tests/RangeImporterTests"
        )
    ]
)

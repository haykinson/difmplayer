// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DIFMPlayer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DIFMPlayer", targets: ["DIFMPlayer"])
    ],
    targets: [
        .executableTarget(
            name: "DIFMPlayer",
            path: "Sources/DIFMPlayer",
            exclude: ["Resources/Info.plist"]
        )
    ]
)

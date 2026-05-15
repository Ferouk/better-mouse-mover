// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BMM",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "bmm", targets: ["BMM"])
    ],
    targets: [
        .executableTarget(
            name: "BMM",
            path: "Sources/BMM"
        )
    ]
)

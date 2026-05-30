// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CampusLock",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "CampusLockCore", targets: ["CampusLockCore"])
    ],
    targets: [
        .target(name: "CampusLockCore"),
        .testTarget(
            name: "CampusLockCoreTests",
            dependencies: ["CampusLockCore"]
        )
    ]
)

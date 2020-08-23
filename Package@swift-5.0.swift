// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CocoaLumberjack",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_10),
        .watchOS(.v3),
        .tvOS(.v9)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CocoaLumberjack",
            targets: ["CocoaLumberjack"]),
        .library(
            name: "CocoaLumberjackSwift",
            targets: ["CocoaLumberjackSwift"]),
        .library(
            name: "CocoaLumberjackSwiftLogBackend",
            targets: ["CocoaLumberjackSwiftLogBackend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "CocoaLumberjack",
                exclude: ["Supporting Files"]),
        .target(name: "CocoaLumberjackSwiftSupport",
                dependencies: ["CocoaLumberjack"]),
        .target(name: "CocoaLumberjackSwift",
                dependencies: ["CocoaLumberjack", "CocoaLumberjackSwiftSupport"],
                exclude: ["Supporting Files"]),
        .target(name: "CocoaLumberjackSwiftLogBackend",
                dependencies: ["CocoaLumberjack", "Logging"]),
        .testTarget(name: "CocoaLumberjackTests",
                    dependencies: ["CocoaLumberjack"]),
        .testTarget(name: "CocoaLumberjackSwiftTests",
                    dependencies: ["CocoaLumberjackSwift"]),
        .testTarget(name: "CocoaLumberjackSwiftLogBackendTests",
                    dependencies: ["CocoaLumberjackSwiftLogBackend"]),
    ]
)

// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: Array<SwiftSetting> = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "CocoaLumberjack",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v5),
        .visionOS(.v1),
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
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CocoaLumberjack",
            exclude: ["Supporting Files"],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]),
        .target(
            name: "CocoaLumberjackSwiftSupport",
            dependencies: ["CocoaLumberjack"]),
        .target(
            name: "CocoaLumberjackSwift",
            dependencies: [
                "CocoaLumberjack",
                "CocoaLumberjackSwiftSupport",
            ],
            exclude: ["Supporting Files"],
            swiftSettings: swiftSettings),
        .target(
            name: "CocoaLumberjackSwiftLogBackend",
            dependencies: [
                "CocoaLumberjack",
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "CocoaLumberjackTests",
            dependencies: ["CocoaLumberjack"]),
        .testTarget(
            name: "CocoaLumberjackSwiftTests",
            dependencies: ["CocoaLumberjackSwift"],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "CocoaLumberjackSwiftLogBackendTests",
            dependencies: ["CocoaLumberjackSwiftLogBackend"],
            swiftSettings: swiftSettings),
    ]
)

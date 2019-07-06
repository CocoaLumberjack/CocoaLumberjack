// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CocoaLumberjack",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CocoaLumberjack",
            type: .dynamic,
            targets: ["CocoaLumberjack"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "CocoaLumberjack",
                path: ".",
                exclude: ["Classes/CocoaLumberjack.swift",
                          "Classes/DDAssert.swift"],
                sources: ["Classes"],
                publicHeadersPath: "Classes/Include/Public"),
//        .target(name: "CocoaLumberjackTestsHelper",
//                dependencies: ["CocoaLumberjack"],
//                path: "Tests",
//                sources: ["Library"],
//                publicHeadersPath: "Library"),
        .testTarget(name: "Tests",
                    dependencies: ["CocoaLumberjack"],
                    path: "Tests",
                    exclude: [],
                    sources: ["Tests"])
    ]
)

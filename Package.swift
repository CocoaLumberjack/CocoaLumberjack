// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

struct CocoaLumberjackPackage {
    class Package {
        static let name = "CocoaLumberjack"
        class Library {
            static let name = "CocoaLumberjack"
        }
        class Target {
            static let objectiveC = "CocoaLumberjack"
            static let swift = "CocoaLumberjackSwift"
        }
    }
}

let package = Package(
    name: CocoaLumberjackPackage.Package.name,
    platforms: [
        .iOS(.v8),
        .macOS(.v10_10),
        .watchOS(.v3),
        .tvOS(.v9)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: CocoaLumberjackPackage.Package.Library.name,
            targets: [CocoaLumberjackPackage.Package.Target.objectiveC,
                      CocoaLumberjackPackage.Package.Target.swift
        ]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: CocoaLumberjackPackage.Package.Target.objectiveC,
                exclude: ["Supporting Files"]),
        
//                sources: ["Classes"],
//                publicHeadersPath: "Classes/Include"),
        .target(name: CocoaLumberjackPackage.Package.Target.swift,
                dependencies: ["CocoaLumberjack"],
                exclude: ["Supporting Files"]),
//        .testTarget(name: "Tests",
//                    dependencies: ["CocoaLumberjack"],
//                    path: "Tests",
//                    exclude: [],
//                    sources: ["Tests"])
    ]
)

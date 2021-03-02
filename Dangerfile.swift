import Foundation
import Danger

fileprivate extension Danger.File {
    var isInSources: Bool { hasPrefix("Sources/") }
    var isInTests: Bool { hasPrefix("Tests/") }
    var isInDemos: Bool { hasPrefix("Demos/") }
    var isInBenchmarking: Bool { hasPrefix("Benchmarking/") }

    var isInVendor: Bool { contains("/Vendor/") }
    var isInFMDB: Bool { contains("/FMDB/") }

    var isSourceFile: Bool {
        hasSuffix(".swift") || hasSuffix(".h") || hasSuffix(".m")
    }

    private static let spmOnlyTargetNames: Set<String> = [
        "CocoaLumberjackSwiftLogBackend",
    ]
    var isSPMOnlySourceFile: Bool {
        guard isSourceFile else { return false }
        if isInSources {
            return Self.spmOnlyTargetNames.contains(where: { contains("/\($0)/") })
        } else if isInTests {
            return Self.spmOnlyTargetNames.contains(where: { contains("/\($0)Tests/") })
        }
        return false
    }

    var isSwiftPackageDefintion: Bool {
        hasPrefix("Package") && hasSuffix(".swift")
    }

    var isDangerfile: Bool {
        self == "Dangerfile.swift"
    }
}

let danger = Danger()
let git = danger.git

// Sometimes it's a README fix, or something like that - which isn't relevant for
// including in a project's CHANGELOG for example
let isDeclaredTrivial = danger.github?.pullRequest.title.contains("#trivial") ?? false
let hasSourceChanges = (git.modifiedFiles + git.createdFiles).contains { $0.isInSources }

// Make it more obvious that a PR is a work in progress and shouldn't be merged yet
if danger.github?.pullRequest.title.contains("WIP") == true {
    warn("PR is marked as Work in Progress")
}

// Warn when there is a big PR
if let additions = danger.github?.pullRequest.additions, let deletions = danger.github?.pullRequest.deletions,
   case let sum = additions + deletions, sum > 1000 {
    warn("Pull request is relatively big (\(sum) lines changed). If this PR contains multiple changes, consider splitting it into separate PRs for easier reviews.")
}

// Changelog entries are required for changes to library files.
if hasSourceChanges && !isDeclaredTrivial && !git.modifiedFiles.contains("CHANGELOG.md") {
  warn("Any changes to library code should be reflected in the CHANGELOG. Please consider adding a note there about your change.")
}

// Warn when library files has been updated but not tests.
if hasSourceChanges && !git.modifiedFiles.contains(where: { $0.isInTests }) {
  warn("The library files were changed, but the tests remained unmodified. Consider updating or adding to the tests to match the library changes.")
}

// Run SwiftLint
SwiftLint.lint(.modifiedAndCreatedFiles(directory: "Sources"))

// Added (or removed) library files need to be added (or removed) from the
// Carthage Xcode project to avoid breaking things for our Carthage users.
let xcodeProjectFile: Danger.File = "Lumberjack.xcodeproj/project.pbxproj"
let xcodeProjectWasModified = git.modifiedFiles.contains(xcodeProjectFile)
if (git.createdFiles + git.deletedFiles).contains(where: { $0.isInSources && $0.isSourceFile && !$0.isSPMOnlySourceFile })
    && !xcodeProjectWasModified {
  fail("Added or removed library files require the Carthage Xcode project to be updated.")
}

// Check if Carthage modified and CocoaPods didn't or vice-versa
let podspecWasModified = git.modifiedFiles.contains("CocoaLumberjack.podspec")
if xcodeProjectWasModified && !podspecWasModified {
  warn("The Carthage project was modified but CocoaPods podspec wasn't. Did you forget to update the podspec?")
}
if !xcodeProjectWasModified && podspecWasModified {
  warn("The CocoaPods podspec was modified but the Carthage project wasn't. Did you forget to update the xcodeproj?")
}

// Check xcodeproj settings are not changed
// Check to see if any of our project files contains a line with "SOURCE_ROOT" which indicates that the file isn't in sync with Finder.
if xcodeProjectWasModified {
    let acceptedSettings: Set<String> = [
        "APPLICATION_EXTENSION_API_ONLY",
        "ASSETCATALOG_COMPILER_APPICON_NAME",
        "ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME",
        "ATTRIBUTES",
        "CODE_SIGN_IDENTITY",
        "COMBINE_HIDPI_IMAGES",
        "FRAMEWORK_VERSION",
        "GCC_PRECOMPILE_PREFIX_HEADER",
        "GCC_PREFIX_HEADER",
        "IBSC_MODULE",
        "INFOPLIST_FILE",
        "MODULEMAP_FILE",
        "PRIVATE_HEADERS_FOLDER_PATH",
        "PRODUCT_BUNDLE_IDENTIFIER",
        "PRODUCT_NAME",
        "PUBLIC_HEADERS_FOLDER_PATH",
        "SDKROOT",
        "SUPPORTED_PLATFORMS",
        "TARGETED_DEVICE_FAMILY",
        "WRAPPER_EXTENSION",
    ]
    [xcodeProjectFile]
        .lazy
        .filter { FileManager.default.fileExists(atPath: $0) }
        .forEach { projectFile in
            danger.utils.readFile(projectFile).split(separator: "\n").enumerated().forEach { (offset, line) in
                if line.contains("sourceTree = SOURCE_ROOT;") &&
                    line.contains("PBXFileReference") &&
                    !line.contains("path = Sources/CocoaLumberjackSwiftSupport/include/") {
                    warn(message: "Files should be in sync with project structure", file: projectFile, line: offset + 1)
                }
                if let range = line.range(of: "[A-Z_]+ = .*;", options: .regularExpression) {
                    let setting = String(line[range].prefix(while: { $0 != " " }))
                    if !acceptedSettings.contains(setting) {
                        warn(message: "Xcode settings need to remain in Configs/*.xcconfig. Please move " + setting + " to the xcconfig file", file: projectFile, line: offset + 1)
                    }
                }
            }
    }
}

// Check Copyright
let copyrightLines = (
    source: [
        "// Software License Agreement (BSD License)",
        "//",
        "// Copyright (c) 2010-2021, Deusty, LLC",
        "// All rights reserved.",
        "//",
        "// Redistribution and use of this software in source and binary forms,",
        "// with or without modification, are permitted provided that the following conditions are met:",
        "//",
        "// * Redistributions of source code must retain the above copyright notice,",
        "//   this list of conditions and the following disclaimer.",
        "//",
        "// * Neither the name of Deusty nor the names of its contributors may be used",
        "//   to endorse or promote products derived from this software without specific",
        "//   prior written permission of Deusty, LLC.",
    ],
    demos: [
        "//",
        "//  ",
        "//  ",
        "//",
        "//  CocoaLumberjack Demos",
        "//",
    ],
    benchmarking: [
        "//",
        "//  ",
        "//  ",
        "//",
        "//  CocoaLumberjack Benchmarking",
        "//",
    ]
)

// let sourcefilesToCheck = Dir.glob("*/*/*") // uncomment when we want to test all the files (locally)
let sourcefilesToCheck = Set(git.modifiedFiles + git.createdFiles)
let filesWithInvalidCopyright = sourcefilesToCheck.lazy
    .filter { $0.isSourceFile }
    .filter { !$0.isSwiftPackageDefintion }
    .filter { !$0.isDangerfile }
    .filter { !$0.isInVendor && !$0.isInFMDB }
    .filter { FileManager.default.fileExists(atPath: $0) }
    .filter {
        // Use correct copyright lines depending on source file location
        let (expectedLines, shouldMatchExactly): (Array<String>, Bool)
        if $0.isInDemos {
            expectedLines = copyrightLines.demos
            shouldMatchExactly = false
        } else if $0.isInBenchmarking {
            expectedLines = copyrightLines.benchmarking
            shouldMatchExactly = false
        } else {
            expectedLines = copyrightLines.source
            shouldMatchExactly = true
        }
        let actualLines = danger.utils.readFile($0).split(separator: "\n").lazy.map(String.init)
        if shouldMatchExactly {
            return !actualLines.starts(with: expectedLines)
        } else {
            return !zip(actualLines, expectedLines).allSatisfy { $0.starts(with: $1) }
        }
}
if !filesWithInvalidCopyright.isEmpty {
    filesWithInvalidCopyright.forEach {
        markdown(message: "Invalid copyright!", file: $0, line: 1)
    }
    warn("""
         Copyright is not valid. See our default copyright in all of our files (Sources, Demos and Benchmarking use different formats).
         Invalid files:
         \(filesWithInvalidCopyright.map { "- \($0)" }.joined(separator: "\n"))
         """)
}

// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2025, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

/// Returns a String of the current filename, without full path or extension.
/// Analogous to the C preprocessor macro `THIS_FILE`.
public func currentFileName(_ fileName: StaticString = #file) -> String {
    var str = String(describing: fileName)
    if let idx = str.range(of: "/", options: .backwards)?.upperBound {
        str = String(str[idx...])
    }
    if let idx = str.range(of: ".", options: .backwards)?.lowerBound {
        str = String(str[..<idx])
    }
    return str
}

// swiftlint:disable identifier_name
// swiftlint doesn't like func names that begin with a capital letter - deprecated
@available(*, deprecated, message: "Please use currentFileName", renamed: "currentFileName")
public func CurrentFileName(_ fileName: StaticString = #file) -> String {
    currentFileName(fileName)
}
// swiftlint:enable identifier_name

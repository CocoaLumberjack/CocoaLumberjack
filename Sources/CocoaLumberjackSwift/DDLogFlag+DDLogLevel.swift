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

#if SWIFT_PACKAGE
public import CocoaLumberjack
#endif

extension DDLogFlag {
    public static func from(_ logLevel: DDLogLevel) -> DDLogFlag {
        DDLogFlag(rawValue: logLevel.rawValue)
    }

	public init(_ logLevel: DDLogLevel) {
        self = DDLogFlag(rawValue: logLevel.rawValue)
	}

    /// Returns the log level, or the lowest equivalent.
    public func toLogLevel() -> DDLogLevel {
        if let ourValid = DDLogLevel(rawValue: rawValue) {
            return ourValid
        } else {
            if contains(.verbose) {
                return .verbose
            } else if contains(.debug) {
                return .debug
            } else if contains(.info) {
                return .info
            } else if contains(.warning) {
                return .warning
            } else if contains(.error) {
                return .error
            } else {
                return .off
            }
        }
    }
}

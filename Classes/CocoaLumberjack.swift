// Software License Agreement (BSD License)
//
// Copyright (c) 2014-2016, Deusty, LLC
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

import Foundation

extension DDLogFlag {
    public static func from(_ logLevel: DDLogLevel) -> DDLogFlag {
        return DDLogFlag(rawValue: logLevel.rawValue)
    }
    
    public init(_ logLevel: DDLogLevel) {
        self = DDLogFlag(rawValue: logLevel.rawValue)
    }
    
    ///returns the log level, or the lowest equivalant.
    public func toLogLevel() -> DDLogLevel {
        if let ourValid = DDLogLevel(rawValue: rawValue) {
            return ourValid
        } else {
            if contains(.Verbose) {
                return DDLogLevel.Verbose
            } else if contains(.Debug) {
                return DDLogLevel.Debug
            } else if contains(.Info) {
                return DDLogLevel.Info
            } else if contains(.Warning) {
                return DDLogLevel.Warning
            } else if contains(.Error) {
                return DDLogLevel.Error
            } else {
                return DDLogLevel.Off
            }
        }
    }
}

public var defaultDebugLevel = DDLogLevel.Verbose

public func resetDefaultDebugLevel() {
    defaultDebugLevel = DDLogLevel.Verbose
}

public func _DDLogMessage(_ message: () -> String, level: DDLogLevel, flag: DDLogFlag, context: Int, file: StaticString, function: StaticString, line: UInt, tag: AnyObject?, asynchronous: Bool, ddlog: DDLog) {
    if level.rawValue & flag.rawValue != 0 {
        // Tell the DDLogMessage constructor to copy the C strings that get passed to it.
        let logMessage = DDLogMessage(message: message(), level: level, flag: flag, context: context, file: String(file), function: String(function), line: line, tag: tag, options: [.CopyFile, .CopyFunction], timestamp: nil)
        ddlog.log(asynchronous: asynchronous, message: logMessage)
    }
}

public func DDLogDebug(_ message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: DDLogFlag.Debug, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogInfo(_ message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: DDLogFlag.Info, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogWarn(_ message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: DDLogFlag.Warning, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogVerbose(_ message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: DDLogFlag.Verbose, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogError(_ message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = false, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: DDLogFlag.Error, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

/// Returns a String of the current filename, without full path or extension.
///
/// Analogous to the C preprocessor macro `THIS_FILE`.
public func CurrentFileName(_ fileName: StaticString = #file) -> String {
    var str = NSString(string: String(fileName))
    var path = str.lastPathComponent
    
    return String(path)
}

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
    public static func fromLogLevel(_ logLevel: DDLogLevel) -> DDLogFlag {
        return DDLogFlag(rawValue: logLevel.rawValue)
    }
	
	public init(_ logLevel: DDLogLevel) {
        self = DDLogFlag(rawValue: logLevel.rawValue)
	}
    
    ///returns the log level, or the lowest equivalant.
    public func toLogLevel() -> DDLogLevel {
        if let ourValid = DDLogLevel(rawValue: self.rawValue) {
            return ourValid
        } else {
            let logFlag:DDLogFlag = self
            
            if logFlag.contains(.verbose) {
                return .verbose
            } else if logFlag.contains(.debug) {
                return .debug
            } else if logFlag.contains(.info) {
                return .info
            } else if logFlag.contains(.warning) {
                return .warning
            } else if logFlag.contains(.error) {
                return .error
            } else {
                return .off
            }
        }
    }
}

public var defaultDebugLevel = DDLogLevel.verbose

public func resetDefaultDebugLevel() {
    defaultDebugLevel = DDLogLevel.verbose
}

@available(*, deprecated, message: "Use one of the DDLog*() functions if appropriate or call _DDLogMessage()")
public func SwiftLogMacro(_ isAsynchronous: Bool, level: DDLogLevel, flag flg: DDLogFlag, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, string: @autoclosure () -> String, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(string, level: level, flag: flg, context: context, file: file, function: function, line: line, tag: tag, asynchronous: isAsynchronous, ddlog: ddlog)
}

public func _DDLogMessage(_ message: @autoclosure () -> String, level: DDLogLevel, flag: DDLogFlag, context: Int, file: StaticString, function: StaticString, line: UInt, tag: AnyObject?, asynchronous: Bool, ddlog: DDLog) {
    if level.rawValue & flag.rawValue != 0 {
        // Tell the DDLogMessage constructor to copy the C strings that get passed to it.
        let logMessage = DDLogMessage(message: message(), level: level, flag: flag, context: context, file: String(describing: file), function: String(describing: function), line: line, tag: tag, options: [.copyFile, .copyFunction], timestamp: nil)
        ddlog.log(asynchronous, message: logMessage)
    }
}

public func DDLogDebug(_ message: @autoclosure () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .debug, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogInfo(_ message: @autoclosure () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .info, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogWarn(_ message: @autoclosure () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .warning, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogVerbose(_ message: @autoclosure () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .verbose, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogError(_ message: @autoclosure () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = false, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .error, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

/// Returns a String of the current filename, without full path or extension.
///
/// Analogous to the C preprocessor macro `THIS_FILE`.
public func CurrentFileName(_ fileName: StaticString = #file) -> String {
    var str = String(describing: fileName)
    if let idx = str.range(of: "/", options: .backwards)?.upperBound {
        str = str.substring(from: idx)
    }
    if let idx = str.range(of: ".", options: .backwards)?.lowerBound {
        str = str.substring(to: idx)
    }
    return str
}

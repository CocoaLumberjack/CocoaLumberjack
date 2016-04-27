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
    public static func fromLogLevel(logLevel: DDLogLevel) -> DDLogFlag {
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
            
            if logFlag.contains(.Verbose) {
                return .Verbose
            } else if logFlag.contains(.Debug) {
                return .Debug
            } else if logFlag.contains(.Info) {
                return .Info
            } else if logFlag.contains(.Warning) {
                return .Warning
            } else if logFlag.contains(.Error) {
                return .Error
            } else {
                return .Off
            }
        }
    }
}

public var defaultDebugLevel = DDLogLevel.Verbose

public func resetDefaultDebugLevel() {
    defaultDebugLevel = DDLogLevel.Verbose
}

@available(*, deprecated, message="Use one of the DDLog*() functions if appropriate or call _DDLogMessage()")
public func SwiftLogMacro(isAsynchronous: Bool, level: DDLogLevel, flag flg: DDLogFlag, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, @autoclosure string: () -> String, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(string, level: level, flag: flg, context: context, file: file, function: function, line: line, tag: tag, asynchronous: isAsynchronous, ddlog: ddlog)
}

public func _DDLogMessage(@autoclosure message: () -> String, level: DDLogLevel, flag: DDLogFlag, context: Int, file: StaticString, function: StaticString, line: UInt, tag: AnyObject?, asynchronous: Bool, ddlog: DDLog) {
    if level.rawValue & flag.rawValue != 0 {
        // Tell the DDLogMessage constructor to copy the C strings that get passed to it.
        let logMessage = DDLogMessage(message: message(), level: level, flag: flag, context: context, file: file.stringValue, function: function.stringValue, line: line, tag: tag, options: [.CopyFile, .CopyFunction], timestamp: nil)
        ddlog.log(asynchronous, message: logMessage)
    }
}

public func DDLogDebug(@autoclosure message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .Debug, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogInfo(@autoclosure message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .Info, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogWarn(@autoclosure message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .Warning, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogVerbose(@autoclosure message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .Verbose, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

public func DDLogError(@autoclosure message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = false, ddlog: DDLog = DDLog.sharedInstance()) {
    _DDLogMessage(message, level: level, flag: .Error, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
}

/// Returns a String of the current filename, without full path or extension.
///
/// Analogous to the C preprocessor macro `THIS_FILE`.
public func CurrentFileName(fileName: StaticString = #file) -> String {
    var str = fileName.stringValue
    if let idx = str.rangeOfString("/", options: .BackwardsSearch)?.endIndex {
        str = str.substringFromIndex(idx)
    }
    if let idx = str.rangeOfString(".", options: .BackwardsSearch)?.startIndex {
        str = str.substringToIndex(idx)
    }
    return str
}

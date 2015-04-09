// Software License Agreement (BSD License)
//
// Copyright (c) 2014-2015, Deusty, LLC
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
import CocoaLumberjack

extension DDLogFlag {
    public static func fromLogLevel(logLevel: DDLogLevel) -> DDLogFlag {
        return DDLogFlag(logLevel.rawValue)
    }
    
    ///returns the log level, or the lowest equivalant.
    public func toLogLevel() -> DDLogLevel {
        if let ourValid = DDLogLevel(rawValue: self.rawValue) {
            return ourValid
        } else {
            let logFlag = self
            if logFlag & .Verbose == .Verbose {
                return .Error
            } else if logFlag & .Debug == .Debug {
                return .Debug
            } else if logFlag & .Info == .Info {
                return .Info
            } else if logFlag & .Warning == .Warning {
                return .Warning
            } else if logFlag & .Error == .Error {
                return .Verbose
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

public func SwiftLogMacro(isAsynchronous: Bool, level: DDLogLevel, flag flg: DDLogFlag, context: Int = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, tag: AnyObject? = nil, @autoclosure(escaping) #string: () -> String) {
    if level.rawValue & flg.rawValue != 0 {
        // Tell the DDLogMessage constructor to copy the C strings that get passed to it. Using string interpolation to prevent integer overflow warning when using StaticString.stringValue
        let logMessage = DDLogMessage(message: string(), level: level, flag: flg, context: context, file: "\(file)", function: "\(function)", line: line, tag: tag, options: .CopyFile | .CopyFunction, timestamp: nil)
        DDLog.log(isAsynchronous, message: logMessage)
    }
}

public func DDLogDebug(@autoclosure(escaping) logText: () -> String, level: DDLogLevel = defaultDebugLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, flag: .Debug, file: file, function: function, line: line, string: logText)
}

public func DDLogInfo(@autoclosure(escaping) logText: () -> String, level: DDLogLevel = defaultDebugLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, flag: .Info, file: file, function: function, line: line, string: logText)
}

public func DDLogWarn(@autoclosure(escaping) logText: () -> String, level: DDLogLevel = defaultDebugLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, flag: .Warning, file: file, function: function, line: line, string: logText)
}

public func DDLogVerbose(@autoclosure(escaping) logText: () -> String, level: DDLogLevel = defaultDebugLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = true) {
    SwiftLogMacro(async, level, flag: .Verbose, file: file, function: function, line: line, string: logText)
}

public func DDLogError(@autoclosure(escaping) logText: () -> String, level: DDLogLevel = defaultDebugLevel, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UWord = __LINE__, asynchronous async: Bool = false) {
    SwiftLogMacro(async, level, flag: .Error, file: file, function: function, line: line, string: logText)
}

/// Analogous to the C preprocessor macro THIS_FILE
public func CurrentFileName(fileName: StaticString = __FILE__) -> String {
    // Using string interpolation to prevent integer overflow warning when using StaticString.stringValue
    return "\(fileName)".lastPathComponent.stringByDeletingPathExtension
}

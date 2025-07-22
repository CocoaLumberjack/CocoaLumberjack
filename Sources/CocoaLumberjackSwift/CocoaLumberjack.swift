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

@_exported public import CocoaLumberjack
#if SWIFT_PACKAGE
public import CocoaLumberjackSwiftSupport
#endif

@inlinable
public func _DDLogMessage(_ messageFormat: @autoclosure () -> DDLogMessageFormat,
                          level: DDLogLevel,
                          flag: DDLogFlag,
                          context: Int,
                          file: StaticString,
                          function: StaticString,
                          line: UInt,
                          tag: Any?,
                          asynchronous: Bool?,
                          ddlog: DDLog) {
    // The `dynamicLogLevel` will always be checked here (instead of being passed in).
    // We cannot "mix" it with the `DDDefaultLogLevel`, because otherwise the compiler won't strip strings that are not logged.
    if level.rawValue & flag.rawValue != 0 && dynamicLogLevel.rawValue & flag.rawValue != 0 {
        let logMessage = DDLogMessage(messageFormat(),
                                      level: level,
                                      flag: flag,
                                      context: context,
                                      file: file,
                                      function: function,
                                      line: line,
                                      tag: tag)
        ddlog.log(asynchronous: asynchronous ?? asyncLoggingEnabled, message: logMessage)
    }
}

@inlinable
public func DDLogDebug(_ message: @autoclosure () -> DDLogMessageFormat,
                       level: DDLogLevel = DDDefaultLogLevel,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: Any? = nil,
                       asynchronous: Bool? = nil,
                       ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .debug,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: asynchronous,
                  ddlog: ddlog)
}

@inlinable
public func DDLogInfo(_ message: @autoclosure () -> DDLogMessageFormat,
                      level: DDLogLevel = DDDefaultLogLevel,
                      context: Int = 0,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      tag: Any? = nil,
                      asynchronous: Bool? = nil,
                      ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .info,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: asynchronous,
                  ddlog: ddlog)
}

@inlinable
public func DDLogWarn(_ message: @autoclosure () -> DDLogMessageFormat,
                      level: DDLogLevel = DDDefaultLogLevel,
                      context: Int = 0,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      tag: Any? = nil,
                      asynchronous: Bool? = nil,
                      ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .warning,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: asynchronous,
                  ddlog: ddlog)
}

@inlinable
public func DDLogVerbose(_ message: @autoclosure () -> DDLogMessageFormat,
                         level: DDLogLevel = DDDefaultLogLevel,
                         context: Int = 0,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         tag: Any? = nil,
                         asynchronous: Bool? = nil,
                         ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .verbose,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: asynchronous,
                  ddlog: ddlog)
}

@inlinable
public func DDLogError(_ message: @autoclosure () -> DDLogMessageFormat,
                       level: DDLogLevel = DDDefaultLogLevel,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: Any? = nil,
                       asynchronous: Bool? = nil,
                       ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .error,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: asynchronous ?? false,
                  ddlog: ddlog)
}

@available(*, deprecated, message: "Use an interpolated DDLogMessageFormat instead")
@inlinable
@_disfavoredOverload
public func _DDLogMessage(_ message: @autoclosure () -> Any,
                          level: DDLogLevel,
                          flag: DDLogFlag,
                          context: Int,
                          file: StaticString,
                          function: StaticString,
                          line: UInt,
                          tag: Any?,
                          asynchronous: Bool?,
                          ddlog: DDLog) {
    // This will lead to `messageFormat` and `message` being equal on DDLogMessage,
    // which is what the legacy initializer of DDLogMessage does as well.
    _DDLogMessage(.init(_formattedMessage: String(describing: message())),
                  level: level,
                  flag: flag,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: asynchronous,
                  ddlog: ddlog)
}

@available(*, deprecated, message: "Use an interpolated DDLogMessageFormat instead")
@inlinable
@_disfavoredOverload
public func DDLogDebug(_ message: @autoclosure () -> Any,
                       level: DDLogLevel = DDDefaultLogLevel,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: Any? = nil,
                       asynchronous async: Bool? = nil,
                       ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .debug,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: ddlog)
}

@available(*, deprecated, message: "Use an interpolated DDLogMessageFormat instead")
@inlinable
@_disfavoredOverload
public func DDLogInfo(_ message: @autoclosure () -> Any,
                      level: DDLogLevel = DDDefaultLogLevel,
                      context: Int = 0,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      tag: Any? = nil,
                      asynchronous async: Bool? = nil,
                      ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .info,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: ddlog)
}

@available(*, deprecated, message: "Use an interpolated DDLogMessageFormat instead")
@inlinable
@_disfavoredOverload
public func DDLogWarn(_ message: @autoclosure () -> Any,
                      level: DDLogLevel = DDDefaultLogLevel,
                      context: Int = 0,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line,
                      tag: Any? = nil,
                      asynchronous async: Bool? = nil,
                      ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .warning,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: ddlog)
}

@available(*, deprecated, message: "Use an interpolated DDLogMessageFormat instead")
@inlinable
@_disfavoredOverload
public func DDLogVerbose(_ message: @autoclosure () -> Any,
                         level: DDLogLevel = DDDefaultLogLevel,
                         context: Int = 0,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         tag: Any? = nil,
                         asynchronous async: Bool? = nil,
                         ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .verbose,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: ddlog)
}

@available(*, deprecated, message: "Use an interpolated DDLogMessageFormat instead")
@inlinable
@_disfavoredOverload
public func DDLogError(_ message: @autoclosure () -> Any,
                       level: DDLogLevel = DDDefaultLogLevel,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: Any? = nil,
                       asynchronous async: Bool? = nil,
                       ddlog: DDLog = .sharedInstance) {
    _DDLogMessage(message(),
                  level: level,
                  flag: .error,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async ?? false,
                  ddlog: ddlog)
}

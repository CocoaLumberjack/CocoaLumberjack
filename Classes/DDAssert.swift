// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2019, Deusty, LLC
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

/**
 * Replacement for Swift's `assert` function that will output a log message even when assertions
 * are disabled.
 *
 * - Parameters:
 *   - condition: The condition to test. Unlike `Swift.assert`, `condition` is always evaluated,
 *     even when assertions are disabled.
 *   - message: A string to log (using `DDLogError`) if `condition` evaluates to `false`.
 *     The default is an empty string.
 */
@inlinable
public func DDAssert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "", context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = false, ddlog: DDLog = DDLog.sharedInstance) {
    if !condition() {
        let evaluated = message()
        DDLogError(evaluated, level: .all, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
        Swift.assertionFailure(evaluated, file: file, line: line)
    }
}

/**
 * Replacement for Swift's `assertionFailure` function that will output a log message even
 * when assertions are disabled.
 *
 * - Parameters:
 *   - message: A string to log (using `DDLogError`). The default is an empty string.
 */
@inlinable
public func DDAssertionFailure(_ message: @autoclosure () -> String = "", context: Int = 0, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = false, ddlog: DDLog = DDLog.sharedInstance) {
    let evaluated = message()
    DDLogError(evaluated, level: .all, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
    Swift.assertionFailure(evaluated, file: file, line: line)
}

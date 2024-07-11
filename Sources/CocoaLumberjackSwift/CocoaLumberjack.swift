// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2024, Deusty, LLC
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

// swiftlint:disable file_length

#if canImport(Synchronization)
import Synchronization
#endif
@_exported import CocoaLumberjack
#if SWIFT_PACKAGE
import CocoaLumberjackSwiftSupport
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

#if canImport(Synchronization)
#if compiler(>=6.0)
extension DDLogLevel: @retroactive AtomicRepresentable {}
#else
extension DDLogLevel: AtomicRepresentable {}
#endif

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
private let _dynamicLogLevel = Atomic(DDLogLevel.all)
#endif

private let _dynamicLogLevelLock = NSLock()
#if swift(>=5.9)
nonisolated(unsafe) private var _dynamicLogLevelStorage = DDLogLevel.all
#else
private var _dynamicLogLevelStorage = DDLogLevel.all
#endif

/// The log level that can dynamically limit log messages (vs. the static ``DDDefaultLogLevel``). This log level will only be checked, if the message passes the ``DDDefaultLogLevel``.
public var dynamicLogLevel: DDLogLevel {
    get {
#if canImport(Synchronization)
        if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
            return _dynamicLogLevel.load(ordering: .relaxed)
        }
#endif
        _dynamicLogLevelLock.lock()
        defer { _dynamicLogLevelLock.unlock() }
        return _dynamicLogLevelStorage
    }
    set {
#if canImport(Synchronization)
        if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
            _dynamicLogLevel.store(newValue, ordering: .relaxed)
            return
        }
#endif
        _dynamicLogLevelLock.lock()
        defer { _dynamicLogLevelLock.unlock() }
        _dynamicLogLevelStorage = newValue
    }
}

/// Resets the ``dynamicLogLevel`` to ``DDLogLevel/all``.
/// - SeeAlso: ``dynamicLogLevel``
@inlinable
public func resetDynamicLogLevel() {
    dynamicLogLevel = .all
}

@available(*, deprecated, message: "Please use dynamicLogLevel", renamed: "dynamicLogLevel")
public var defaultDebugLevel: DDLogLevel {
    get {
        dynamicLogLevel
    }
    set {
        dynamicLogLevel = newValue
    }
}

@available(*, deprecated, message: "Please use resetDynamicLogLevel", renamed: "resetDynamicLogLevel")
public func resetDefaultDebugLevel() {
    resetDynamicLogLevel()
}

#if canImport(Synchronization)
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
private let _asyncLoggingEnabled = Atomic(true)
#endif

private let _asyncLoggingEnabledLock = NSLock()
#if swift(>=5.9)
nonisolated(unsafe) private var _asyncLoggingEnabledStorage = true
#else
private var _asyncLoggingEnabledStorage = true
#endif

/// If `true`, all logs (except errors) are logged asynchronously by default.
public var asyncLoggingEnabled: Bool {
    get {
#if canImport(Synchronization)
        if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
            return _asyncLoggingEnabled.load(ordering: .relaxed)
        }
#endif
        _asyncLoggingEnabledLock.lock()
        defer { _asyncLoggingEnabledLock.unlock() }
        return _asyncLoggingEnabledStorage
    }
    set {
#if canImport(Synchronization)
        if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
            _asyncLoggingEnabled.store(newValue, ordering: .relaxed)
            return
        }
#endif
        _asyncLoggingEnabledLock.lock()
        defer { _asyncLoggingEnabledLock.unlock() }
        _asyncLoggingEnabledStorage = newValue
    }
}

@frozen
public struct DDLogMessageFormat: ExpressibleByStringInterpolation {
    public typealias StringLiteralType = String

    @usableFromInline
    struct Storage {
#if swift(>=5.6)
        @usableFromInline
        typealias VArg = any CVarArg
#else
        @usableFromInline
        typealias VArg = CVarArg
#endif
        @usableFromInline
        let requiresArgumentParsing: Bool
        @usableFromInline
        var format: String
        @usableFromInline
        var args: Array<VArg> {
            willSet {
                // We only assert here to let the compiler optimize it away.
                // The setter will be used repeatedly during string interpolation, thus should stay fast.
                assert(requiresArgumentParsing || newValue.isEmpty, "Non-empty arguments always require argument parsing!")
            }
        }

        @usableFromInline
        init(requiresArgumentParsing: Bool, format: String, args: Array<VArg>) {
            precondition(requiresArgumentParsing || args.isEmpty, "Non-empty arguments always require argument parsing!")
            self.requiresArgumentParsing = requiresArgumentParsing
            self.format = format
            self.args = args
        }

        @available(*, deprecated, message: "Use initializer specifying the need for argument parsing: init(requiresArgumentParsing:format:args:)")
        @usableFromInline
        init(format: String, args: Array<VArg>) {
            self.init(requiresArgumentParsing: !args.isEmpty, format: format, args: args)
        }

        @usableFromInline
        mutating func addString(_ string: String) {
            format.append(string.replacingOccurrences(of: "%", with: "%%"))
        }

        @inlinable
        mutating func addValue(_ arg: VArg, withSpecifier specifier: String) {
            format.append(specifier)
            args.append(arg)
        }
    }

    @frozen
    public struct StringInterpolation: StringInterpolationProtocol {
        @usableFromInline
        var storage: Storage

        @inlinable
        public init(literalCapacity: Int, interpolationCount: Int) {
            var format = String()
            format.reserveCapacity(literalCapacity)
            var args = Array<Storage.VArg>()
            args.reserveCapacity(interpolationCount)
            storage = .init(requiresArgumentParsing: true, format: format, args: args)
        }

        @inlinable
        public mutating func appendLiteral(_ literal: StringLiteralType) {
            storage.addString(literal)
        }

        @inlinable
        public mutating func appendInterpolation<S: StringProtocol>(_ string: S) {
            storage.addValue(String(string), withSpecifier: "%@")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: Int8) {
            storage.addValue(int, withSpecifier: "%c")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: UInt8) {
            storage.addValue(int, withSpecifier: "%c")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: Int16) {
            storage.addValue(int, withSpecifier: "%i")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: UInt16) {
            storage.addValue(int, withSpecifier: "%u")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: Int32) {
            storage.addValue(int, withSpecifier: "%li")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: UInt32) {
            storage.addValue(int, withSpecifier: "%lu")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: Int64) {
            storage.addValue(int, withSpecifier: "%lli")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: UInt64) {
            storage.addValue(int, withSpecifier: "%llu")
        }

        @inlinable
        public mutating func appendInterpolation(_ int: Int) {
#if arch(arm64) || arch(x86_64)
            storage.addValue(int, withSpecifier: "%lli")
#else
            storage.addValue(int, withSpecifier: "%li")
#endif
        }

        @inlinable
        public mutating func appendInterpolation(_ int: UInt) {
#if arch(arm64) || arch(x86_64)
            storage.addValue(int, withSpecifier: "%llu")
#else
            storage.addValue(int, withSpecifier: "%lu")
#endif
        }

        @inlinable
        public mutating func appendInterpolation(_ flt: Float) {
            storage.addValue(flt, withSpecifier: "%f")
        }

        @inlinable
        public mutating func appendInterpolation(_ dbl: Double) {
            storage.addValue(dbl, withSpecifier: "%lf")
        }

        @inlinable
        public mutating func appendInterpolation(_ bool: Bool) {
            storage.addValue(bool, withSpecifier: "%i") // bools are printed as ints
        }

        @inlinable
        public mutating func appendInterpolation<Convertible: ReferenceConvertible>(_ convertible: Convertible) {
            if convertible is Storage.VArg {
                print("""
                [WARNING]: CocoaLumberjackSwift is creating a \(DDLogMessageFormat.self) with an interpolation conforming to `CVarArg` \
                using the overload for `ReferenceConvertible` interpolations!
                Please report this as a bug, including the following snippet:
                ```
                Convertible: \(Convertible.self), ReferenceType: \(Convertible.ReferenceType.self), type(of: convertible): \(type(of: convertible))
                ```
                """)
            }
            // This should be safe, sine the compiler should convert it to the reference.
            // swiftlint:disable:next force_cast
            storage.addValue(convertible as? Storage.VArg ?? convertible as! Convertible.ReferenceType, withSpecifier: "%@")
        }

        @inlinable
        public mutating func appendInterpolation<Obj: NSObject>(_ object: Obj) {
            storage.addValue(object, withSpecifier: "%@")
        }

        @_disfavoredOverload
        public mutating func appendInterpolation(_ any: Any) {
            appendInterpolation(String(describing: any))
        }
    }

    @usableFromInline
    let storage: Storage

    @inlinable
    var format: String { storage.format }
    @inlinable
    var args: Array<Storage.VArg> { storage.args }

    @inlinable
    var formatted: String {
        guard storage.requiresArgumentParsing else { return storage.format }
        return String(format: storage.format, arguments: storage.args)
    }

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        storage = .init(requiresArgumentParsing: false, format: value, args: [])
    }

    @inlinable
    public init(stringInterpolation: StringInterpolation) {
        storage = stringInterpolation.storage
    }

    @inlinable
    internal init(_formattedMessage: String) {
        storage = .init(requiresArgumentParsing: false, format: _formattedMessage, args: [])
    }
}

extension DDLogMessage {
    @inlinable
    public convenience init(_ format: DDLogMessageFormat,
                            level: DDLogLevel,
                            flag: DDLogFlag,
                            context: Int = 0,
                            file: StaticString = #file,
                            function: StaticString = #function,
                            line: UInt = #line,
                            tag: Any? = nil,
                            timestamp: Date? = nil) {
        self.init(format: format.format,
                  formatted: format.formatted,
                  level: level,
                  flag: flag,
                  context: context,
                  file: String(describing: file),
                  function: String(describing: function),
                  line: line,
                  tag: tag,
                  options: [.dontCopyMessage],
                  timestamp: timestamp)
    }
}

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

// swiftlint:enable file_length

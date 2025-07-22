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

@frozen
public struct DDLogMessageFormat: ExpressibleByStringInterpolation {
    public typealias StringLiteralType = String

    @usableFromInline
    struct Storage {
        @usableFromInline
        typealias VArg = any CVarArg

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

        // Move printed string out of inlinable code portion
        @usableFromInline
        func _warnReferenceConvertibleCVarArgInterpolation<Convertible: ReferenceConvertible>(_ convertible: Convertible) {
            print("""
            [WARNING]: CocoaLumberjackSwift is creating a \(DDLogMessageFormat.self) with an interpolation conforming to `CVarArg` \
            using the overload for `ReferenceConvertible` interpolations!
            Please report this as a bug, including the following snippet:
            ```
            Convertible: \(Convertible.self), ReferenceType: \(Convertible.ReferenceType.self), type(of: convertible): \(type(of: convertible))
            ```
            """)
        }

        @inlinable
        public mutating func appendInterpolation<Convertible: ReferenceConvertible>(_ convertible: Convertible) {
            if convertible is Storage.VArg {
               _warnReferenceConvertibleCVarArgInterpolation(convertible)
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

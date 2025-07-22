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

#if canImport(Synchronization)
public import Synchronization
#endif
#if SWIFT_PACKAGE
public import CocoaLumberjack
#endif

#if canImport(Synchronization)
#if compiler(>=6.0) && !COCOAPODS // CocoaPods seems to merge the modules.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DDLogLevel: @retroactive AtomicRepresentable {}
#else
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DDLogLevel: AtomicRepresentable {}
#endif

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
private let _dynamicLogLevel = Atomic(DDLogLevel.all)
#endif

private let _dynamicLogLevelLock = NSLock()
nonisolated(unsafe) private var _dynamicLogLevelStorage = DDLogLevel.all

private func _readDynamicLogLevel() -> DDLogLevel {
#if canImport(Synchronization)
    if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
        return _dynamicLogLevel.load(ordering: .relaxed)
    }
#endif
    _dynamicLogLevelLock.lock()
    defer { _dynamicLogLevelLock.unlock() }
    return _dynamicLogLevelStorage
}

private func _writeDynamicLogLevel(_ newValue: DDLogLevel) {
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

/// The log level that can dynamically limit log messages (vs. the static ``DDDefaultLogLevel``). This log level will only be checked, if the message passes the ``DDDefaultLogLevel``.
public nonisolated(unsafe) var dynamicLogLevel: DDLogLevel {
    get {
        _readDynamicLogLevel()
    }
    set {
        _writeDynamicLogLevel(newValue)
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
nonisolated(unsafe) private var _asyncLoggingEnabledStorage = true

private func _readAsyncLoggingEnabled() -> Bool {
#if canImport(Synchronization)
    if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
        return _asyncLoggingEnabled.load(ordering: .relaxed)
    }
#endif
    _asyncLoggingEnabledLock.lock()
    defer { _asyncLoggingEnabledLock.unlock() }
    return _asyncLoggingEnabledStorage
}

private func _writeAsyncLoggingEnabled(_ newValue: Bool) {
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

/// If `true`, all logs (except errors) are logged asynchronously by default.
public nonisolated(unsafe) var asyncLoggingEnabled: Bool {
    get {
        _readAsyncLoggingEnabled()
    }
    set {
        _writeAsyncLoggingEnabled(newValue)
    }
}

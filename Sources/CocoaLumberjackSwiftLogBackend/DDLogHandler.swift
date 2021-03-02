// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2021, Deusty, LLC
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

import CocoaLumberjack
import Logging

extension Logger.Level {
    @inlinable
    var ddLogLevelAndFlag: (DDLogLevel, DDLogFlag) {
        switch self {
        case .trace: return (.verbose, .verbose)
        case .debug: return (.debug, .debug)
        case .info, .notice: return (.info, .info)
        case .warning: return (.warning, .warning)
        case .error, .critical: return (.error, .error)
        }
    }
}

extension DDLogMessage {
    /// Contains the swift-log details of a given log message.
    public struct SwiftLogInformation: Equatable {
        /// Contains information about the swift-log logger that logged this message.
        public struct LoggerInformation: Equatable {
            /// The label of the swift-log logger that logged this message.
            public let label: String
            /// The metadata of the swift-log logger that logged this message.
            public let metadata: Logger.Metadata
        }

        /// Contains information about the swift-log message thas was logged.
        public struct MessageInformation: Equatable {
            /// The original swift-log message.
            public let message: Logger.Message
            /// The original swift-log level of the message. This could be more fine-grained than `DDLogMessage.level` & `DDLogMessage.flag`.
            public let level: Logger.Level
            /// The original swift-log metadata of the message.
            public let metadata: Logger.Metadata?
            /// The original swift-log source of the message.
            public let source: String
        }

        /// The information about the swift-log logger that logged this message.
        public let logger: LoggerInformation
        /// The information about the swift-log message that was logged.
        public let message: MessageInformation
    }

    /// The swift-log information of this log message. This only exists for messages logged via swift-log.
    /// - SeeAlso: `DDLogMessage.SwiftLogInformation`
    @inlinable
    public var swiftLogInfo: SwiftLogInformation? {
        return (self as? SwiftLogMessage)?._swiftLogInfo
    }
}

/// This class (intentionally internal) is only an "encapsulation" layer above `DDLogMessage`.
/// It's basically an implementation detail of `DDLogMessage.swiftLogInfo`.
@usableFromInline
final class SwiftLogMessage: DDLogMessage {
    // SwiftLint doesn't like that this starts with an underscore.
    // It only tolerates that for private vars, but this cant' be private (because @usableFromInline).
    // swiftlint:disable identifier_name
    @usableFromInline
    let _swiftLogInfo: SwiftLogInformation
    // swiftlint:enable identifier_name

    @usableFromInline
    init(loggerLabel: String,
         loggerMetadata: Logger.Metadata,
         message: Logger.Message,
         level: Logger.Level,
         metadata: Logger.Metadata?,
         source: String,
         file: String,
         function: String,
         line: UInt) {
        _swiftLogInfo = .init(logger: .init(label: loggerLabel, metadata: loggerMetadata),
                              message: .init(message: message,
                                             level: level,
                                             metadata: metadata,
                                             source: source))
        let (ddLogLevel, ddLogFlag) = level.ddLogLevelAndFlag
        super.init(message: String(describing: message),
                   level: ddLogLevel,
                   flag: ddLogFlag,
                   context: 0,
                   file: file,
                   function: function,
                   line: line,
                   tag: nil,
                   options: .dontCopyMessage, // Swift will bridge to NSString. No need to make an additional copy.
                   timestamp: nil) // Passing nil will make DDLogMessage create the timestamp which saves us the bridging between Date and NSDate.
    }

    override func isEqual(_ object: Any?) -> Bool {
        return super.isEqual(object) && (object as? SwiftLogMessage)?._swiftLogInfo == _swiftLogInfo
    }
}

/// A swift-log `LogHandler` implementation that forwards messages to a given `DDLog` instance.
public struct DDLogHandler: LogHandler {
    @usableFromInline
    struct Configuration {
        @usableFromInline
        struct SyncLogging {
            @usableFromInline
            let tresholdLevel: Logger.Level
            @usableFromInline
            let metadataKey: Logger.Metadata.Key
        }
        @usableFromInline
        let log: DDLog
        @usableFromInline
        let syncLogging: SyncLogging
    }

    @usableFromInline
    struct LoggerInfo {
        @usableFromInline
        let label: String
        @usableFromInline
        var logLevel: Logger.Level
        @usableFromInline
        var metadata: Logger.Metadata = [:]
    }

    @usableFromInline
    let config: Configuration
    @usableFromInline
    var loggerInfo: LoggerInfo

    @inlinable
    public var logLevel: Logger.Level {
        get { return loggerInfo.logLevel }
        set { loggerInfo.logLevel = newValue }
    }
    @inlinable
    public var metadata: Logger.Metadata {
        get { return loggerInfo.metadata }
        set { loggerInfo.metadata = newValue }
    }

    @inlinable
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { return metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }

    private init(config: Configuration, loggerInfo: LoggerInfo) {
        self.config = config
        self.loggerInfo = loggerInfo
    }

    /// Returns whether a message with the given level and the given metadata should be logged asynchronous.
    /// - Parameters:
    ///   - level: The level at which the message was logged.
    ///   - metadata: The metadata associated with the message.
    /// - Returns: Whether to log the message asynchronous.
    @usableFromInline
    func _logAsync(level: Logger.Level, metadata: Logger.Metadata?) -> Bool { // swiftlint:disable:this identifier_name
        if level >= config.syncLogging.tresholdLevel {
            // Easiest check -> level is above treshold. Not async.
            return false
        } else if case .stringConvertible(let logSynchronous as Bool) = metadata?[config.syncLogging.metadataKey] {
            // There's a metadata value, return it's value. We need to invert it since it defines whether to log _synchronous_.
            return !logSynchronous
        } else {
            // If we're below the treshold and no metadata value is set -> we're logging async.
            return true
        }
    }

    @inlinable
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        let slMessage = SwiftLogMessage(loggerLabel: loggerInfo.label,
                                        loggerMetadata: loggerInfo.metadata,
                                        message: message,
                                        level: level,
                                        metadata: metadata,
                                        source: source,
                                        file: file,
                                        function: function,
                                        line: line)
        config.log.log(asynchronous: _logAsync(level: level, metadata: metadata), message: slMessage)
    }
}

extension DDLogHandler {
    /// The default key to control per message whether to log it synchronous or asynchronous.
    public static var defaultSynchronousLoggingMetadataKey: Logger.Metadata.Key {
        return "log-synchronous"
    }

    /// Creates a new `LogHandler` factory using `DDLogHandler` with the given parameters.
    /// - Parameters:
    ///   - log: The `DDLog` instance to use for logging. Defaults to `DDLog.sharedInstance`.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to `.info`.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to `.error`.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to `DDLogHandler.defaultSynchronousLoggingMetadataKey`.
    /// - Returns: A new `LogHandler` factory using `DDLogHandler` that can be passed to `LoggingSystem.bootstrap`.
    /// - SeeAlso: `DDLog`, `LoggingSystem.boostrap`
    public static func handlerFactory(for log: DDLog = .sharedInstance,
                                      defaultLogLevel: Logger.Level = .info,
                                      loggingSynchronousAsOf syncLoggingTreshold: Logger.Level = .error,
                                      synchronousLoggingMetadataKey: Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey) -> (String) -> LogHandler {
        let config = DDLogHandler.Configuration(
            log: log,
            syncLogging: .init(tresholdLevel: syncLoggingTreshold,
                               metadataKey: synchronousLoggingMetadataKey)
        )
        return {
            DDLogHandler(config: config, loggerInfo: .init(label: $0, logLevel: defaultLogLevel))
        }
    }
}

extension LoggingSystem {
    /// Bootraps the logging system with a new `LogHandler` factory using `DDLogHandler`.
    /// - Parameters:
    ///   - log: The `DDLog` instance to use for logging. Defaults to `DDLog.sharedInstance`.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to `.info`.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to `.error`.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to `DDLogHandler.defaultSynchronousLoggingMetadataKey`.
    /// - SeeAlso: `DDLogHandler.handlerFactory`, `LoggingSystem.bootstrap`
    @inlinable
    public static func bootstrapWithCocoaLumberjack(for log: DDLog = .sharedInstance,
                                                    defaultLogLevel: Logger.Level = .info,
                                                    loggingSynchronousAsOf syncLoggingTreshold: Logger.Level = .error,
                                                    synchronousLoggingMetadataKey: Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey) {
        bootstrap(DDLogHandler.handlerFactory(for: log,
                                              defaultLogLevel: defaultLogLevel,
                                              loggingSynchronousAsOf: syncLoggingTreshold,
                                              synchronousLoggingMetadataKey: synchronousLoggingMetadataKey))
    }
}

// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2023, Deusty, LLC
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
    public struct SwiftLogInformation: Equatable, Sendable {
        /// Contains information about the swift-log logger that logged this message.
        public struct LoggerInformation: Equatable, Sendable {
            /// Contains the metadata from the various sources of on a logger.
            /// Currently this can be the logger itself, as well as its metadata provider
            public struct MetadataSources: Equatable, Sendable {
                /// The metadata of the swift-log logger that logged this message.
                public let logger: Logger.Metadata
                /// The metadata of the metadata provider on the swift-log logger that logged this message.
                public let provider: Logger.Metadata?
            }

            /// The label of the swift-log logger that logged this message.
            public let label: String
            /// The metadata of the swift-log logger that logged this message.
            public let metadataSources: MetadataSources

            /// The metadata of the swift-log logger that logged this message.
            @available(*, deprecated, renamed: "metadataSources.logger")
            public var metadata: Logger.Metadata { metadataSources.logger }
        }

        /// Contains information about the swift-log message thas was logged.
        public struct MessageInformation: Equatable, Sendable {
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

        /// Merges the metadata from all layers together.
        /// The metadata on the logger provides the base.
        /// Metadata from the logger's metadata provider (if any) trumps the base.
        /// Metadata from the logged message again trumps both the base and the metadata from the logger's metadata provider.
        /// Essentially: `logger.metadata < logger.metadataProvider < message.metadata`
        /// - Note: Accessing this property performs the merge! Accessing it multiple times can be a performance issue!
        public var mergedMetadata: Logger.Metadata {
            var merged = logger.metadataSources.logger
            if let providerMetadata = logger.metadataSources.provider {
                merged.merge(providerMetadata, uniquingKeysWith: { $1 })
            }
            if let messageMetadata = message.metadata {
                merged.merge(messageMetadata, uniquingKeysWith: { $1 })
            }
            return merged
        }
    }

    /// The swift-log information of this log message. This only exists for messages logged via swift-log.
    /// - SeeAlso: `DDLogMessage.SwiftLogInformation`
    @inlinable
    public var swiftLogInfo: SwiftLogInformation? {
        (self as? SwiftLogMessage)?._swiftLogInfo
    }
}

/// This class (intentionally internal) is only an "encapsulation" layer above `DDLogMessage`.
/// It's basically an implementation detail of `DDLogMessage.swiftLogInfo`.
@usableFromInline
final class SwiftLogMessage: DDLogMessage {
    @usableFromInline
    let _swiftLogInfo: SwiftLogInformation

    @usableFromInline
    init(loggerLabel: String,
         loggerMetadata: Logger.Metadata,
         loggerProvidedMetadata: Logger.Metadata?,
         message: Logger.Message,
         level: Logger.Level,
         metadata: Logger.Metadata?,
         source: String,
         file: String,
         function: String,
         line: UInt) {
        _swiftLogInfo = .init(logger: .init(label: loggerLabel,
                                            metadataSources: .init(logger: loggerMetadata,
                                                                   provider: loggerProvidedMetadata)),
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

    // Not removed due to `@usableFromInline`.
    @usableFromInline
    @available(*, deprecated, renamed: "init(loggerLabel:loggerMetadata:loggerMetadata:message:level:metadata:source:file:function:line:)")
    convenience init(loggerLabel: String,
         loggerMetadata: Logger.Metadata,
         message: Logger.Message,
         level: Logger.Level,
         metadata: Logger.Metadata?,
         source: String,
         file: String,
         function: String,
         line: UInt) {
        self.init(loggerLabel: loggerLabel,
                  loggerMetadata: loggerMetadata,
                  loggerProvidedMetadata: nil,
                  message: message,
                  level: level,
                  metadata: metadata,
                  source: source,
                  file: file,
                  function: function,
                  line: line)
    }

    override func isEqual(_ object: Any?) -> Bool {
        super.isEqual(object) && (object as? SwiftLogMessage)?._swiftLogInfo == _swiftLogInfo
    }
}

/// A swift-log `LogHandler` implementation that forwards messages to a given `DDLog` instance.
public struct DDLogHandler: LogHandler {
    @usableFromInline
    struct Configuration: Sendable {
        @usableFromInline
        struct SyncLogging: Sendable {
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
    struct LoggerInfo: Sendable {
        @usableFromInline
        struct MetadataSources: Sendable {
            @usableFromInline
            var provider: Logger.MetadataProvider?
            @usableFromInline
            var logger: Logger.Metadata = [:]
        }

        @usableFromInline
        let label: String
        @usableFromInline
        var logLevel: Logger.Level
        @usableFromInline
        var metadataSources: MetadataSources

        // Not removed due to `@usableFromInline`
        @usableFromInline
        @available(*, deprecated, renamed: "metadataSources.logger")
        var metadata: Logger.Metadata {
            get { metadataSources.logger }
            set { metadataSources.logger = newValue }
        }
    }

    @usableFromInline
    let config: Configuration
    @usableFromInline
    var loggerInfo: LoggerInfo

    @inlinable
    public var logLevel: Logger.Level {
        get { loggerInfo.logLevel }
        set { loggerInfo.logLevel = newValue }
    }
    @inlinable
    public var metadataProvider: Logger.MetadataProvider? {
        get { loggerInfo.metadataSources.provider }
        set { loggerInfo.metadataSources.provider = newValue }
    }
    @inlinable
    public var metadata: Logger.Metadata {
        get { loggerInfo.metadataSources.logger }
        set { loggerInfo.metadataSources.logger = newValue }
    }

    @inlinable
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
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
    func _logAsync(level: Logger.Level, metadata: Logger.Metadata?) -> Bool {
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
                                        loggerMetadata: loggerInfo.metadataSources.logger,
                                        loggerProvidedMetadata: loggerInfo.metadataSources.provider?.get(),
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
        "log-synchronous"
    }

    /// Creates a new `LogHandler` factory using `DDLogHandler` with the given parameters.
    /// - Parameters:
    ///   - log: The `DDLog` instance to use for logging. Defaults to `DDLog.sharedInstance`.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to `.info`.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to `.error`.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to `DDLogHandler.defaultSynchronousLoggingMetadataKey`.
    /// - Returns: A new `LogHandler` factory using `DDLogHandler` that can be passed to `LoggingSystem.bootstrap`.
    /// - SeeAlso: `DDLog`, `LoggingSystem.boostrap`
    public static func handlerFactory(
        for log: DDLog = .sharedInstance,
        defaultLogLevel: Logger.Level = .info,
        loggingSynchronousAsOf syncLoggingTreshold: Logger.Level = .error,
        synchronousLoggingMetadataKey: Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey
    ) -> (String, Logger.MetadataProvider?) -> LogHandler {
        let config = DDLogHandler.Configuration(
            log: log,
            syncLogging: .init(tresholdLevel: syncLoggingTreshold,
                               metadataKey: synchronousLoggingMetadataKey)
        )
        return {
            DDLogHandler(config: config, loggerInfo: .init(label: $0, logLevel: defaultLogLevel, metadataSources: .init(provider: $1)))
        }
    }

    /// Creates a new `LogHandler` factory using `DDLogHandler` with the given parameters.
    /// - Parameters:
    ///   - log: The `DDLog` instance to use for logging. Defaults to `DDLog.sharedInstance`.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to `.info`.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to `.error`.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to `DDLogHandler.defaultSynchronousLoggingMetadataKey`.
    /// - Returns: A new `LogHandler` factory using `DDLogHandler` that can be passed to `LoggingSystem.bootstrap`.
    /// - SeeAlso: `DDLog`, `LoggingSystem.boostrap`
    @inlinable
    public static func handlerFactory(
        for log: DDLog = .sharedInstance,
        defaultLogLevel: Logger.Level = .info,
        loggingSynchronousAsOf syncLoggingTreshold: Logger.Level = .error,
        synchronousLoggingMetadataKey: Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey
    ) -> (String) -> LogHandler {
        let factory: (String, Logger.MetadataProvider?) -> LogHandler = handlerFactory(
            for: log,
            defaultLogLevel: defaultLogLevel,
            loggingSynchronousAsOf: syncLoggingTreshold,
            synchronousLoggingMetadataKey: synchronousLoggingMetadataKey
        )
        return { factory($0, nil) }
    }
}

extension LoggingSystem {
    /// Bootraps the logging system with a new `LogHandler` factory using `DDLogHandler`.
    /// - Parameters:
    ///   - log: The `DDLog` instance to use for logging. Defaults to `DDLog.sharedInstance`.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to `.info`.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to `.error`.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to `DDLogHandler.defaultSynchronousLoggingMetadataKey`.
    ///   - metadataProvider: The (global) metadata provider to use with the setup. Defaults to `nil`.
    /// - SeeAlso: `DDLogHandler.handlerFactory`, `LoggingSystem.bootstrap`
    @inlinable
    public static func bootstrapWithCocoaLumberjack(
        for log: DDLog = .sharedInstance,
        defaultLogLevel: Logger.Level = .info,
        loggingSynchronousAsOf syncLoggingTreshold: Logger.Level = .error,
        synchronousLoggingMetadataKey: Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey,
        metadataProvider: Logger.MetadataProvider? = nil
    ) {
        bootstrap(DDLogHandler.handlerFactory(for: log,
                                              defaultLogLevel: defaultLogLevel,
                                              loggingSynchronousAsOf: syncLoggingTreshold,
                                              synchronousLoggingMetadataKey: synchronousLoggingMetadataKey),
                  metadataProvider: metadataProvider)
    }
}

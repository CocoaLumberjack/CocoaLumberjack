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

public import CocoaLumberjack
public import Logging

/// A swift-log ``LogHandler`` implementation that forwards messages to a given ``DDLog`` instance.
public struct DDLogHandler: LogHandler {
    @usableFromInline
    struct Configuration: Sendable {
        @usableFromInline
        struct SyncLogging: Sendable {
            @usableFromInline
            let tresholdLevel: Logging.Logger.Level
            @usableFromInline
            let metadataKey: Logging.Logger.Metadata.Key
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
            var provider: Logging.Logger.MetadataProvider?
            @usableFromInline
            var logger: Logging.Logger.Metadata = [:]
        }

        @usableFromInline
        let label: String
        @usableFromInline
        var logLevel: Logging.Logger.Level
        @usableFromInline
        var metadataSources: MetadataSources

        // Not removed due to `@usableFromInline`
        @usableFromInline
        @available(*, deprecated, renamed: "metadataSources.logger")
        var metadata: Logging.Logger.Metadata {
            get { metadataSources.logger }
            set { metadataSources.logger = newValue }
        }
    }

    @usableFromInline
    let config: Configuration
    @usableFromInline
    var loggerInfo: LoggerInfo

    @inlinable
    public var logLevel: Logging.Logger.Level {
        get { loggerInfo.logLevel }
        set { loggerInfo.logLevel = newValue }
    }
    @inlinable
    public var metadataProvider: Logging.Logger.MetadataProvider? {
        get { loggerInfo.metadataSources.provider }
        set { loggerInfo.metadataSources.provider = newValue }
    }
    @inlinable
    public var metadata: Logging.Logger.Metadata {
        get { loggerInfo.metadataSources.logger }
        set { loggerInfo.metadataSources.logger = newValue }
    }

    @inlinable
    public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
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
    func _logAsync(level: Logging.Logger.Level, metadata: Logging.Logger.Metadata?) -> Bool {
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
    public func log(level: Logging.Logger.Level,
                    message: Logging.Logger.Message,
                    metadata: Logging.Logger.Metadata?,
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

/// A typealias for the "old" log handler factory.
@preconcurrency
public typealias OldLogHandlerFactory = @Sendable (String) -> any LogHandler
/// A typealias for the log handler factory.
@preconcurrency
public typealias LogHandlerFactory = @Sendable (String, Logging.Logger.MetadataProvider?) -> any LogHandler

extension DDLogHandler {
    /// The default key to control per message whether to log it synchronous or asynchronous.
    public static var defaultSynchronousLoggingMetadataKey: Logging.Logger.Metadata.Key {
        "log-synchronous"
    }

    /// Creates a new ``LogHandler`` factory using ``DDLogHandler`` with the given parameters.
    /// - Parameters:
    ///   - log: The ``DDLog`` instance to use for logging. Defaults to ``DDLog/sharedInstance``.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to ``Logging/Logger/Level/info``.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to ``Logging/Logger/Level/error``.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to ``DDLogHandler/defaultSynchronousLoggingMetadataKey``.
    /// - Returns: A new ``LogHandler`` factory using ``DDLogHandler`` that can be passed to ``LoggingSystem/bootstrap``.
    /// - SeeAlso: ``DDLog``, ``LoggingSystem/boostrap``
    public static func handlerFactory(
        for log: DDLog = .sharedInstance,
        defaultLogLevel: Logging.Logger.Level = .info,
        loggingSynchronousAsOf syncLoggingTreshold: Logging.Logger.Level = .error,
        synchronousLoggingMetadataKey: Logging.Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey
    ) -> LogHandlerFactory {
        let config = DDLogHandler.Configuration(
            log: log,
            syncLogging: .init(tresholdLevel: syncLoggingTreshold,
                               metadataKey: synchronousLoggingMetadataKey)
        )
        return {
            DDLogHandler(config: config, loggerInfo: .init(label: $0, logLevel: defaultLogLevel, metadataSources: .init(provider: $1)))
        }
    }

    /// Creates a new ``LogHandler`` factory using ``DDLogHandler`` with the given parameters.
    /// - Parameters:
    ///   - log: The ``DDLog`` instance to use for logging. Defaults to ``DDLog/sharedInstance``.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to ``Logging/Logger/Level/info``.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to ``Logging/Logger/Level/error``.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to ``DDLogHandler/defaultSynchronousLoggingMetadataKey``.
    /// - Returns: A new ``LogHandler`` factory using ``DDLogHandler`` that can be passed to ``LoggingSystem/bootstrap``.
    /// - SeeAlso: ``DDLog``, ``LoggingSystem/boostrap``
    @inlinable
    public static func handlerFactory(
        for log: DDLog = .sharedInstance,
        defaultLogLevel: Logging.Logger.Level = .info,
        loggingSynchronousAsOf syncLoggingTreshold: Logging.Logger.Level = .error,
        synchronousLoggingMetadataKey: Logging.Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey
    ) -> OldLogHandlerFactory {
        let factory: LogHandlerFactory = handlerFactory(
            for: log,
            defaultLogLevel: defaultLogLevel,
            loggingSynchronousAsOf: syncLoggingTreshold,
            synchronousLoggingMetadataKey: synchronousLoggingMetadataKey
        )
        return { factory($0, nil) }
    }
}

extension LoggingSystem {
    /// Bootraps the logging system with a new ``LogHandler`` factory using ``DDLogHandler``.
    /// - Parameters:
    ///   - log: The ``DDLog`` instance to use for logging. Defaults to ``DDLog/sharedInstance``.
    ///   - defaultLogLevel: The default log level for new loggers. Defaults to ``Logging/Logger/Level/info``.
    ///   - syncLoggingTreshold: The level as of which log messages should be logged synchronously instead of asynchronously. Defaults to ``Logging/Logger/Level/error``.
    ///   - synchronousLoggingMetadataKey: The metadata key to check on messages to decide whether to log synchronous or asynchronous. Defaults to ``DDLogHandler/defaultSynchronousLoggingMetadataKey``.
    ///   - metadataProvider: The (global) metadata provider to use with the setup. Defaults to `nil`.
    /// - SeeAlso: ``DDLogHandler/handlerFactory``, ``LoggingSystem/bootstrap``
    @inlinable
    public static func bootstrapWithCocoaLumberjack(
        for log: DDLog = .sharedInstance,
        defaultLogLevel: Logging.Logger.Level = .info,
        loggingSynchronousAsOf syncLoggingTreshold: Logging.Logger.Level = .error,
        synchronousLoggingMetadataKey: Logging.Logger.Metadata.Key = DDLogHandler.defaultSynchronousLoggingMetadataKey,
        metadataProvider: Logging.Logger.MetadataProvider? = nil
    ) {
        bootstrap(DDLogHandler.handlerFactory(for: log,
                                              defaultLogLevel: defaultLogLevel,
                                              loggingSynchronousAsOf: syncLoggingTreshold,
                                              synchronousLoggingMetadataKey: synchronousLoggingMetadataKey),
                  metadataProvider: metadataProvider)
    }
}

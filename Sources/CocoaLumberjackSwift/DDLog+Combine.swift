// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2022, Deusty, LLC
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

#if arch(arm64) || arch(x86_64)
#if canImport(Combine)
import Combine

#if SWIFT_PACKAGE
import CocoaLumberjack
import CocoaLumberjackSwiftSupport
#endif

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension DDLog {
    // MARK: - Subscription
    private final class Subscription<S: Subscriber>: NSObject, DDLogger, Combine.Subscription
    where S.Input == DDLogMessage
    { // swiftlint:disable:this opening_brace
        private var subscriber: S?
        private weak var log: DDLog?

        /// Not used but `DDLogger` requires it.
        /// The preferred way to achieve this is to use the `map` Combine operator of the publisher.
        /// Example:
        /// ```
        /// DDLog.sharedInstance.messagePublisher()
        ///     .map { message in /* format message */ }
        ///     .sink(receiveValue: { formattedMessage in /* process formattedMessage */ })
        /// ```
#if compiler(>=5.7)
        var logFormatter: (any DDLogFormatter)?
#else
        var logFormatter: DDLogFormatter?
#endif

        init(log: DDLog, with logLevel: DDLogLevel, subscriber: S) {
            self.subscriber = subscriber
            self.log = log

            super.init()

            log.add(self, with: logLevel)
        }

        func request(_ demand: Subscribers.Demand) {
            // The log messages are endless until canceled, so we won't do any demand management.
            // Combine operators can be used to deal with it as needed.
        }

        func cancel() {
            log?.remove(self)
            subscriber = nil
        }

        func log(message logMessage: DDLogMessage) {
            _ = subscriber?.receive(logMessage)
        }
    }

    // MARK: - Publisher
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public struct MessagePublisher: Combine.Publisher {
        public typealias Output = DDLogMessage
        public typealias Failure = Never

        private let log: DDLog
        private let logLevel: DDLogLevel

        public init(log: DDLog, with logLevel: DDLogLevel) {
            self.log = log
            self.logLevel = logLevel
        }

        public func receive<S>(subscriber: S)
        where S: Subscriber, S.Failure == Failure, S.Input == Output
        { // swiftlint:disable:this opening_brace
            let subscription = Subscription(log: log, with: logLevel, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }

    /**
     * Creates a message publisher.
     *
     * The publisher will add and remove loggers as subscriptions are added and removed.
     *
     * The level that you provide here is a preemptive filter (for performance).
     * That is, the level specified here will be used to filter out logMessages so that
     * the logger is never even invoked for the messages.
     *
     * More information:
     *    See -[DDLog addLogger:with:]
     *
     * - Parameter logLevel: preemptive filter of the message returned by the publisher. All levels are sent by default
     * - Returns: A MessagePublisher that emits LogMessages filtered by the specified logLevel
     **/
    public func messagePublisher(with logLevel: DDLogLevel = .all) -> MessagePublisher {
        MessagePublisher(log: self, with: logLevel)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Output == DDLogMessage {
#if compiler(>=5.7)
    public func formatted(with formatter: any DDLogFormatter) -> Publishers.CompactMap<Self, String> {
        compactMap { formatter.format(message: $0) }
    }
#else
    public func formatted(with formatter: DDLogFormatter) -> Publishers.CompactMap<Self, String> {
        compactMap { formatter.format(message: $0) }
    }
#endif
}
#endif
#endif

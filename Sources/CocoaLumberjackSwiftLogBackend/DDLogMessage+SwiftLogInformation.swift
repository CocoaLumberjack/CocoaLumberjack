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

extension DDLogMessage {
    /// Contains the swift-log details of a given log message.
    public struct SwiftLogInformation: Equatable, Sendable {
        /// Contains information about the swift-log logger that logged this message.
        public struct LoggerInformation: Equatable, Sendable {
            /// Contains the metadata from the various sources of on a logger.
            /// Currently this can be the logger itself, as well as its metadata provider
            public struct MetadataSources: Equatable, Sendable {
                /// The metadata of the swift-log logger that logged this message.
                public let logger: Logging.Logger.Metadata
                /// The metadata of the metadata provider on the swift-log logger that logged this message.
                public let provider: Logging.Logger.Metadata?
            }

            /// The label of the swift-log logger that logged this message.
            public let label: String
            /// The metadata of the swift-log logger that logged this message.
            public let metadataSources: MetadataSources

            /// The metadata of the swift-log logger that logged this message.
            @available(*, deprecated, renamed: "metadataSources.logger")
            public var metadata: Logging.Logger.Metadata { metadataSources.logger }
        }

        /// Contains information about the swift-log message thas was logged.
        public struct MessageInformation: Equatable, Sendable {
            /// The original swift-log message.
            public let message: Logging.Logger.Message
            /// The original swift-log level of the message. This could be more fine-grained than ``DDLogMessage/level``  & ``DDLogMessage/flag``.
            public let level: Logging.Logger.Level
            /// The original swift-log metadata of the message.
            public let metadata: Logging.Logger.Metadata?
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
        public var mergedMetadata: Logging.Logger.Metadata {
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
    @inlinable
    public var swiftLogInfo: SwiftLogInformation? {
        (self as? SwiftLogMessage)?._swiftLogInfo
    }
}

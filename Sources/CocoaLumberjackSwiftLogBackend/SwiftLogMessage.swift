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

extension Logging.Logger.Level {
    @inlinable
    var ddLogLevelAndFlag: (DDLogLevel, DDLogFlag) {
        switch self {
        case .trace: return (.verbose, .verbose)
        case .debug: return (.debug, .debug)
        case .info, .notice: return (.info, .info)
        case .warning: return (.warning, .warning)
        case .error, .critical: return (.error, .error)
        @unknown default: return (.error, .error) // better safe than sorry
        }
    }
}

/// This class (intentionally internal) is only an "encapsulation" layer above ``DDLogMessage``.
/// It's basically an implementation detail of ``DDLogMessage/swiftLogInfo``.
@usableFromInline
final class SwiftLogMessage: DDLogMessage, @unchecked Sendable {
    @usableFromInline
    let _swiftLogInfo: SwiftLogInformation

    @usableFromInline
    init(loggerLabel: String,
         loggerMetadata: Logging.Logger.Metadata,
         loggerProvidedMetadata: Logging.Logger.Metadata?,
         message: Logging.Logger.Message,
         level: Logging.Logger.Level,
         metadata: Logging.Logger.Metadata?,
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
        let msg = String(describing: message)
        super.init(format: msg,
                   formatted: msg, // We have no chance in retrieving the original format here.
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
                     loggerMetadata: Logging.Logger.Metadata,
                     message: Logging.Logger.Message,
                     level: Logging.Logger.Level,
                     metadata: Logging.Logger.Metadata?,
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

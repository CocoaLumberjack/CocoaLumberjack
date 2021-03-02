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

import XCTest
import CocoaLumberjack
@testable import Logging
@testable import CocoaLumberjackSwiftLogBackend

fileprivate final class MockDDLog: DDLog {
    struct LoggedMessage: Equatable {
        let async: Bool
        let message: DDLogMessage
    }

    private(set) var loggedMessages = Array<LoggedMessage>()

    override func log(asynchronous: Bool, message logMessage: DDLogMessage) {
        super.log(asynchronous: asynchronous, message: logMessage)
        loggedMessages.append(LoggedMessage(async: asynchronous, message: logMessage))
    }
}

final class DDLogHandlerTests: XCTestCase {
    private var mockDDLog: MockDDLog!

    private var logSource: String { "CocoaLumberjackSwiftLogBackendTests" }

    override func setUp() {
        super.setUp()
        mockDDLog = MockDDLog()
    }

    override func tearDown() {
        mockDDLog = nil
        super.tearDown()
    }

    func testBootstrappingWithConvenienceMethod() throws {
        // It is important that this is the only test using the convenience method,
        // since another use of it will fail the precondition (multiple bootstrap calls)
        // All other tests must use `LoggingSystem.bootstrapInternal`.
        LoggingSystem.bootstrapWithCocoaLumberjack(for: mockDDLog)
        let logger = Logger(label: "TestLogger")
        let msg: Logger.Message = "test message"
        let logLine: UInt = #line + 1
        logger.info(msg)
        XCTAssertEqual(mockDDLog.loggedMessages.count, 1)
        let loggedMsg = try XCTUnwrap(mockDDLog.loggedMessages.first)
        XCTAssertTrue(loggedMsg.async)
        XCTAssertEqual(loggedMsg.message.message, String(describing: msg))
        XCTAssertEqual(loggedMsg.message.level, .info)
        XCTAssertEqual(loggedMsg.message.flag, .info)
        XCTAssertEqual(loggedMsg.message.file, #file)
        XCTAssertEqual(loggedMsg.message.function, #function)
        XCTAssertEqual(loggedMsg.message.line, logLine)
        XCTAssertNotNil(loggedMsg.message.swiftLogInfo)
        XCTAssertEqual(loggedMsg.message.swiftLogInfo, .init(logger: .init(label: logger.label,
                                                                           metadata: logger.handler.metadata),
                                                             message: .init(message: msg,
                                                                            level: .info,
                                                                            metadata: nil,
                                                                            source: logSource)))
    }

    func testBootstrappingWithExplicitMethod() throws {
        LoggingSystem.bootstrapInternal(DDLogHandler.handlerFactory(for: mockDDLog))
        let logger = Logger(label: "TestLogger")
        let msg: Logger.Message = "test message"
        let logLine: UInt = #line + 1
        logger.info(msg)
        XCTAssertEqual(mockDDLog.loggedMessages.count, 1)
        let loggedMsg = try XCTUnwrap(mockDDLog.loggedMessages.first)
        XCTAssertTrue(loggedMsg.async)
        XCTAssertEqual(loggedMsg.message.message, String(describing: msg))
        XCTAssertEqual(loggedMsg.message.level, .info)
        XCTAssertEqual(loggedMsg.message.flag, .info)
        XCTAssertEqual(loggedMsg.message.file, #file)
        XCTAssertEqual(loggedMsg.message.function, #function)
        XCTAssertEqual(loggedMsg.message.line, logLine)
        XCTAssertNotNil(loggedMsg.message.swiftLogInfo)
        XCTAssertEqual(loggedMsg.message.swiftLogInfo, .init(logger: .init(label: logger.label,
                                                                           metadata: logger.handler.metadata),
                                                             message: .init(message: msg,
                                                                            level: .info,
                                                                            metadata: nil,
                                                                            source: logSource)))
    }

    func testDefaults() throws {
        LoggingSystem.bootstrapInternal(DDLogHandler.handlerFactory())
        let logger = Logger(label: "TestLogger")
        XCTAssertEqual(logger.logLevel, .info)
        XCTAssertTrue(logger.handler is DDLogHandler)
        let ddLogHandler = try XCTUnwrap(logger.handler as? DDLogHandler)
        XCTAssertEqual(ddLogHandler.loggerInfo.label, logger.label)
        XCTAssertTrue(ddLogHandler.loggerInfo.metadata.isEmpty)
        XCTAssertTrue(ddLogHandler.config.log === DDLog.sharedInstance)
        XCTAssertEqual(ddLogHandler.config.syncLogging.tresholdLevel, .error)
        XCTAssertEqual(ddLogHandler.config.syncLogging.metadataKey, DDLogHandler.defaultSynchronousLoggingMetadataKey)
    }

    func testLoggingAllLevels() throws {
        let syncTresholdLevel = Logger.Level.warning
        let syncLoggingMetadataKey: Logger.Metadata.Key = "test-log-sync"
        LoggingSystem.bootstrapInternal(DDLogHandler.handlerFactory(for: mockDDLog,
                                                                    loggingSynchronousAsOf: syncTresholdLevel,
                                                                    synchronousLoggingMetadataKey: syncLoggingMetadataKey))
        var logger = Logger(label: "TestLogger")
        logger.logLevel = .trace // enable all logs
        logger[metadataKey: "test-data"] = "test-value"
        XCTAssertEqual(logger.logLevel, .trace)
        XCTAssertEqual(logger[metadataKey: "test-data"], "test-value")
        let allLevels = Logger.Level.allCases
        let message1Meta: Logger.Metadata = ["msg-data": "msg-value"]
        let message2Meta = message1Meta.merging([syncLoggingMetadataKey: .stringConvertible(true)], uniquingKeysWith: { $1 })
        let logLine1: UInt = #line + 3
        let logLine2 = logLine1 + 1
        for level in allLevels {
            logger.log(level: level, "\(level)-msg", metadata: message1Meta)
            logger.log(level: level, "\(level)-msg-with-sync", metadata: message2Meta)
        }
        XCTAssertEqual(mockDDLog.loggedMessages.count, Logger.Level.allCases.count * 2)
        guard mockDDLog.loggedMessages.count >= Logger.Level.allCases.count * 2 else { return } // prevent test crashes

        zip(allLevels, stride(from: mockDDLog.loggedMessages.startIndex, to: mockDDLog.loggedMessages.endIndex, by: 2)).forEach {
            let level = $0.0

            let loggedMsg1 = mockDDLog.loggedMessages[$0.1]
            XCTAssertEqual(loggedMsg1.async, level < syncTresholdLevel)
            XCTAssertEqual(loggedMsg1.message.message, "\(level)-msg")
            XCTAssertEqual(loggedMsg1.message.level, level.ddLogLevelAndFlag.0)
            XCTAssertEqual(loggedMsg1.message.flag, level.ddLogLevelAndFlag.1)
            XCTAssertEqual(loggedMsg1.message.file, #file)
            XCTAssertEqual(loggedMsg1.message.function, #function)
            XCTAssertEqual(loggedMsg1.message.line, logLine1)
            XCTAssertNotNil(loggedMsg1.message.swiftLogInfo)
            XCTAssertEqual(loggedMsg1.message.swiftLogInfo, .init(logger: .init(label: logger.label,
                                                                                metadata: logger.handler.metadata),
                                                                  message: .init(message: "\(level)-msg",
                                                                                 level: level,
                                                                                 metadata: message1Meta,
                                                                                 source: logSource)))

            let loggedMsg2 = mockDDLog.loggedMessages[$0.1 + 1]
            XCTAssertFalse(loggedMsg2.async)
            XCTAssertEqual(loggedMsg2.message.message, "\(level)-msg-with-sync")
            XCTAssertEqual(loggedMsg2.message.level, level.ddLogLevelAndFlag.0)
            XCTAssertEqual(loggedMsg2.message.flag, level.ddLogLevelAndFlag.1)
            XCTAssertEqual(loggedMsg2.message.file, #file)
            XCTAssertEqual(loggedMsg2.message.function, #function)
            XCTAssertEqual(loggedMsg2.message.line, logLine2)
            XCTAssertNotNil(loggedMsg2.message.swiftLogInfo)
            XCTAssertEqual(loggedMsg2.message.swiftLogInfo, .init(logger: .init(label: logger.label,
                                                                                metadata: logger.handler.metadata),
                                                                  message: .init(message: "\(level)-msg-with-sync",
                                                                                 level: level,
                                                                                 metadata: message2Meta,
                                                                                 source: logSource)))
        }
    }
}

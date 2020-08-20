// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2020, Deusty, LLC
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
        XCTAssertEqual(ddLogHandler.config.syncLoggingTresholdLevel, .error)
    }

    func testLoggingAllLevels() throws {
        let syncTresholdLevel = Logger.Level.warning
        LoggingSystem.bootstrapInternal(DDLogHandler.handlerFactory(for: mockDDLog, loggingSynchronousAsOf: syncTresholdLevel))
        var logger = Logger(label: "TestLogger")
        logger.logLevel = .trace // enable all logs
        logger[metadataKey: "test-data"] = "test-value"
        XCTAssertEqual(logger.logLevel, .trace)
        XCTAssertEqual(logger[metadataKey: "test-data"], "test-value")
        let messageMeta: Logger.Metadata = ["msg-data": "msg-value"]
        let logLine: UInt = #line + 2
        for level in Logger.Level.allCases {
            logger.log(level: level, "\(level)-msg", metadata: messageMeta)
        }
        XCTAssertEqual(mockDDLog.loggedMessages.count, Logger.Level.allCases.count)
        guard mockDDLog.loggedMessages.count >= Logger.Level.allCases.count else { return } // prevent test crashes
        for (idx, level) in Logger.Level.allCases.enumerated() {
            let loggedMsg = mockDDLog.loggedMessages[idx]
            XCTAssertEqual(loggedMsg.async, level < syncTresholdLevel)
            XCTAssertEqual(loggedMsg.message.message, "\(level)-msg")
            XCTAssertEqual(loggedMsg.message.level, level.ddLogLevelAndFlag.0)
            XCTAssertEqual(loggedMsg.message.flag, level.ddLogLevelAndFlag.1)
            XCTAssertEqual(loggedMsg.message.file, #file)
            XCTAssertEqual(loggedMsg.message.function, #function)
            XCTAssertEqual(loggedMsg.message.line, logLine)
            XCTAssertNotNil(loggedMsg.message.swiftLogInfo)
            XCTAssertEqual(loggedMsg.message.swiftLogInfo, .init(logger: .init(label: logger.label,
                                                                               metadata: logger.handler.metadata),
                                                                 message: .init(message: "\(level)-msg",
                                                                                level: level,
                                                                                metadata: messageMeta,
                                                                                source: logSource)))
        }
    }
}

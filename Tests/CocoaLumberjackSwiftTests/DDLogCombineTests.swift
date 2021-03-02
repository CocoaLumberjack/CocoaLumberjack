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

#if canImport(Combine)

@testable import CocoaLumberjackSwift
import Combine
import XCTest

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class DDLogCombineTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()

    private var logFormatter: DDLogFileFormatterDefault {
        //let's return a formatter that doesn't change based where the
        //test is being run.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss:SSS"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return DDLogFileFormatterDefault(dateFormatter: formatter)
    }

    override func setUp() {
        super.setUp()
        DDLog.removeAllLoggers()
    }

    override func tearDown() {
        DDLog.removeAllLoggers()
        self.subscriptions.removeAll()
        super.tearDown()
    }

    func testMessagePublisherWithDDLogLevelAll() {
        DDLog.sharedInstance.messagePublisher()
            .sink(receiveValue: { _ in })
            .store(in: &self.subscriptions)

        XCTAssertEqual(DDLog.allLoggers.count, 1)
        XCTAssertEqual(DDLog.allLoggersWithLevel.count, 1)
        XCTAssertEqual(DDLog.allLoggersWithLevel.last?.level, .all)
    }

    func testMessagePublisherWithSpecifiedLevelMask() {
        DDLog.sharedInstance.messagePublisher(with: .error)
            .sink(receiveValue: { _ in })
            .store(in: &self.subscriptions)

        XCTAssertEqual(DDLog.allLoggers.count, 1)
        XCTAssertEqual(DDLog.allLoggersWithLevel.count, 1)
        XCTAssertEqual(DDLog.allLoggersWithLevel.last?.level, .error)
    }

    func testMessagePublisherRemovedWhenSubscriptionIsCanceled() {
        let sub = DDLog.sharedInstance.messagePublisher()
            .sink(receiveValue: { _ in })

        XCTAssertEqual(DDLog.allLoggers.count, 1)
        XCTAssertEqual(DDLog.allLoggersWithLevel.count, 1)
        XCTAssertEqual(DDLog.allLoggersWithLevel.last?.level, .all)

        sub.cancel()

        XCTAssertTrue(DDLog.allLoggers.isEmpty)
        XCTAssertTrue(DDLog.allLoggersWithLevel.isEmpty)
    }

    func testReceivedValuesWithDDLogLevelAll() {
        var receivedValue = [DDLogMessage]()

        DDLog.sharedInstance.messagePublisher()
            .sink(receiveValue: { receivedValue.append($0) })
            .store(in: &self.subscriptions)

        DDLogError("Error")
        DDLogWarn("Warn")
        DDLogInfo("Info")
        DDLogDebug("Debug")
        DDLogVerbose("Verbose")

        DDLog.flushLog()

        let messages = receivedValue.map { $0.message }
        XCTAssertEqual(messages, ["Error",
                                  "Warn",
                                  "Info",
                                  "Debug",
                                  "Verbose"])

        let levels = receivedValue.map { $0.flag }
        XCTAssertEqual(levels, [.error,
                                .warning,
                                .info,
                                .debug,
                                .verbose])
    }

    func testReceivedValuesWithDDLogLevelWarning() {
        var receivedValue = [DDLogMessage]()

        DDLog.sharedInstance.messagePublisher(with: .warning)
            .sink(receiveValue: { receivedValue.append($0) })
            .store(in: &self.subscriptions)

        DDLogError("Error")
        DDLogWarn("Warn")
        DDLogInfo("Info")
        DDLogDebug("Debug")
        DDLogVerbose("Verbose")

        DDLog.flushLog()

        let messages = receivedValue.map { $0.message }
        XCTAssertEqual(messages, ["Error", "Warn"])

        let levels = receivedValue.map { $0.flag }
        XCTAssertEqual(levels, [.error, .warning])
    }

    func testFormatted() {
        let subject = PassthroughSubject<DDLogMessage, Never>()

        var receivedValue = [String]()

        subject
            .formatted(with: self.logFormatter)
            .sink(receiveValue: { receivedValue.append($0) })
            .store(in: &self.subscriptions)

        subject.send(DDLogMessage(message: "An error occurred",
                                  level: .all,
                                  flag: .error,
                                  context: 42,
                                  file: "Combine.swift",
                                  function: "PerformFailure",
                                  line: 67,
                                  tag: nil,
                                  options: [],
                                  timestamp: Date(timeIntervalSinceReferenceDate: 100)))

        subject.send(DDLogMessage(message: "WARNING: this is incorrect",
                                  level: .all,
                                  flag: .warning,
                                  context: 23,
                                  file: "Combine.swift",
                                  function: "PerformWarning",
                                  line: 90,
                                  tag: nil,
                                  options: [],
                                  timestamp: Date(timeIntervalSinceReferenceDate: 200)))

        XCTAssertEqual(receivedValue, ["2001/01/01 00:01:40:000  An error occurred",
                                       "2001/01/01 00:03:20:000  WARNING: this is incorrect"])
    }
    
    func testQOSNameInstanciation() {
        let name = "UI"
        let qos : qos_class_t = {
            switch DDQualityOfServiceName(rawValue: name) {
                case DDQualityOfServiceName.userInteractive:
                    return QOS_CLASS_USER_INTERACTIVE
                default:
                    return QOS_CLASS_UNSPECIFIED
            }
        }()
        
        XCTAssertEqual(qos, QOS_CLASS_USER_INTERACTIVE)
    }
}

#endif

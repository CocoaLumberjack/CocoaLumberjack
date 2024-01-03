// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2024, Deusty, LLC
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
@testable import CocoaLumberjackSwift

final class DDLogMessageFormatTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMessageFormatCreationWithNoArgs() {
        let format: DDLogMessageFormat = "Message with no args"
        let expectedFormat: String = "Message with no args"
        XCTAssertFalse(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertTrue(format.args.isEmpty)
        XCTAssertEqual(format.formatted, expectedFormat)
    }

    func testMessageFormatCreationWithString() {
        let str: String = "String"
        let substr: Substring = "Substring"
        let format: DDLogMessageFormat = "This is a string: \(str). And this a substring: \(substr)."
        let expectedFormat: String = "This is a string: %@. And this a substring: %@."
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 2)
        XCTAssertEqual(format.args.first as? String, str)
        XCTAssertEqual(format.args.last as? String, String(substr))
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [str, String(substr)]))
    }

    func testMessageFormatCreationWithInts() {
        let int8: Int8 = -7
        let uint8: UInt8 = 7
        let int16: Int16 = -42
        let uint16: UInt16 = 42
        let int32: Int32 = -472345
        let uint32: UInt32 = 472345
        let int64: Int64 = -47234532145
        let uint64: UInt64 = 47234532145
        let int: Int = -2345654
        let uint: UInt = 2345654
        let format: DDLogMessageFormat = "Int8: \(int8); UInt8: \(uint8); Int16: \(int16); UInt16: \(uint16); Int32: \(int32); UInt32: \(uint32); Int64: \(int64); UInt64: \(uint64); Int: \(int); UInt: \(uint)"
        let expectedFormat: String = "Int8: %c; UInt8: %c; Int16: %i; UInt16: %u; Int32: %li; UInt32: %lu; Int64: %lli; UInt64: %llu; Int: %lli; UInt: %llu"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 10)
        guard format.args.count >= 10 else { return } // prevent crashes
        XCTAssertEqual(format.args[0] as? Int8, int8)
        XCTAssertEqual(format.args[1] as? UInt8, uint8)
        XCTAssertEqual(format.args[2] as? Int16, int16)
        XCTAssertEqual(format.args[3] as? UInt16, uint16)
        XCTAssertEqual(format.args[4] as? Int32, int32)
        XCTAssertEqual(format.args[5] as? UInt32, uint32)
        XCTAssertEqual(format.args[6] as? Int64, int64)
        XCTAssertEqual(format.args[7] as? UInt64, uint64)
        XCTAssertEqual(format.args[8] as? Int, int)
        XCTAssertEqual(format.args[9] as? UInt, uint)
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [
            int8, uint8, int16, uint16, int32, uint32, int64, uint64, int, uint,
        ]))
    }

    func testMessageFormatCreationWithFloats() {
        let flt: Float = 42.4344
        let dbl: Double = 42.1345512
        let format: DDLogMessageFormat = "Float: \(flt); Double: \(dbl)"
        let expectedFormat: String = "Float: %f; Double: %lf"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 2)
        XCTAssertEqual(format.args.first as? Float, flt)
        XCTAssertEqual(format.args.last as? Double, dbl)
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [flt, dbl]))
    }

    func testMessageFormatCreationWithReferenceConvertibles() {
        let date = Date()
        let uuid = UUID()
        let indexPath = IndexPath(indexes: [1, 2, 3])
        let format: DDLogMessageFormat = "Date: \(date); UUID: \(uuid); IndexPath: \(indexPath)"
        let expectedFormat: String = "Date: %@; UUID: %@; IndexPath: %@"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 3)
        guard format.args.count >= 3 else { return } // prevent crashes
        XCTAssertEqual((format.args[0] as? NSDate).map { $0 as Date }, date)
        XCTAssertEqual((format.args[1] as? NSUUID).map { $0 as UUID }, uuid)
        XCTAssertEqual((format.args[2] as? NSIndexPath).map { $0 as IndexPath }, indexPath)
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [date as NSDate, uuid as NSUUID, indexPath as NSIndexPath]))
    }

    func testMessageFormatCreationWithNSObjects() {
        final class TestObject: NSObject {}

        let obj = TestObject()
        let format: DDLogMessageFormat = "Object: \(obj)"
        let expectedFormat: String = "Object: %@"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 1)
        XCTAssertIdentical(format.args.first as? NSObject, obj)
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [obj]))
    }

    func testMessageFormatCreationWithOtherTypes() {
        struct TestStruct: CustomStringConvertible {
            var description: String { "STRUCT DESCRIPTION" }
        }

        let other = TestStruct()
        let format: DDLogMessageFormat = "Other: \(other)"
        let expectedFormat: String = "Other: %@"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 1)
        XCTAssertEqual(format.args.first as? String, String(describing: other))
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [String(describing: other)]))
    }

    func testMessageFormatWithSpaces() {
        let format: DDLogMessageFormat = " this is a message that starts and ends with a space "
        let expectedFormat: String = " this is a message that starts and ends with a space "
        XCTAssertFalse(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertTrue(format.args.isEmpty)
        XCTAssertEqual(format.formatted, expectedFormat)
    }

    func testMessageFormatWithPercentInLiteral() {
        let formatWithoutArgs: DDLogMessageFormat = "This message contains % some % percent %20 signs but no args"
        let formatWithArgs: DDLogMessageFormat = "This message contains % some % percent %20 signs and \(1) other stuff at \(12.34)"
        let expectedFormatWithoutArgs = "This message contains % some % percent %20 signs but no args"
        let expectedFormatWithArgs = "This message contains %% some %% percent %%20 signs and %lli other stuff at %lf"
        XCTAssertFalse(formatWithoutArgs.storage.requiresArgumentParsing)
        XCTAssertTrue(formatWithArgs.storage.requiresArgumentParsing)
        XCTAssertEqual(formatWithoutArgs.format, expectedFormatWithoutArgs)
        XCTAssertEqual(formatWithArgs.format, expectedFormatWithArgs)
        XCTAssertTrue(formatWithoutArgs.args.isEmpty)
        XCTAssertFalse(formatWithArgs.args.isEmpty)
        XCTAssertEqual(formatWithArgs.args.count, 2)
        XCTAssertEqual(formatWithoutArgs.formatted, expectedFormatWithoutArgs)
        XCTAssertEqual(formatWithArgs.formatted, String(format: expectedFormatWithArgs, arguments: formatWithArgs.args))
    }
}

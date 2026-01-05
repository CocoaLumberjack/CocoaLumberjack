// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2026, Deusty, LLC
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
    private final class TestObject: NSObject {}

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
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [str, String(substr)]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [str, String(substr)]))
#endif
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
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [
            int8, uint8, int16, uint16, int32, uint32, int64, uint64, int, uint,
        ]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [
            int8, uint8, int16, uint16, int32, uint32, int64, uint64, int, uint,
        ]))
#endif
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
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [flt, dbl]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [flt, dbl]))
#endif
    }

    func testMessageFormatCreationWithBools() {
        let bool: Bool = true
        let format: DDLogMessageFormat = "Bool: \(bool)"
        let expectedFormat: String = "Bool: %i"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 1)
        XCTAssertEqual(format.args.first as? Bool, bool)
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [bool]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [bool]))
#endif
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
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [date as NSDate, uuid as NSUUID, indexPath as NSIndexPath]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [date as NSDate, uuid as NSUUID, indexPath as NSIndexPath]))
#endif
    }

    func testMessageFormatCreationWithNSObjects() {
        let obj = TestObject()
        let format: DDLogMessageFormat = "Object: \(obj)"
        let expectedFormat: String = "Object: %@"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 1)
        XCTAssertIdentical(format.args.first as? NSObject, obj)
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [obj]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [obj]))
#endif
    }

    func testMessageFormatCreationWithOtherTypes() {
        struct TestStruct: Sendable, CustomStringConvertible {
            var description: String { "STRUCT DESCRIPTION" }
        }

        let other = TestStruct()
        let format: DDLogMessageFormat = "Other: \(other)"
        let expectedFormat: String = "Other: %@"
        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 1)
        XCTAssertEqual(format.args.first as? String, String(describing: other))
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: [String(describing: other)]))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: [String(describing: other)]))
#endif
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
#if compiler(>=6.2)
        XCTAssertEqual(formatWithArgs.formatted, unsafe String(format: expectedFormatWithArgs, arguments: formatWithArgs.args))
#else
        XCTAssertEqual(formatWithArgs.formatted, String(format: expectedFormatWithArgs, arguments: formatWithArgs.args))
#endif
    }

    func testMessageFormatWithNonNilOptionalsAndDefaults() {
        let str: String? = "String"
        let substr: Substring? = "Substring"
        let int8: Int8? = -7
        let uint8: UInt8? = 7
        let int16: Int16? = -42
        let uint16: UInt16? = 42
        let int32: Int32? = -472345
        let uint32: UInt32? = 472345
        let int64: Int64? = -47234532145
        let uint64: UInt64? = 47234532145
        let int: Int? = -2345654
        let uint: UInt? = 2345654
        let flt: Float? = 42.4344
        let dbl: Double? = 42.1345512
        let bool: Bool? = true
        let date: Date? = Date()
        let uuid: UUID? = UUID()
        let indexPath: IndexPath? = IndexPath(indexes: [1, 2, 3])
        let obj: TestObject? = TestObject()

        let defaultMsg = "IT WAS NIL"

        let format: DDLogMessageFormat = """
            String: \(str, default: defaultMsg)
            Substring: \(substr, default: defaultMsg)
            Int8: \(int8, default: defaultMsg)
            UInt8: \(uint8, default: defaultMsg)
            Int16: \(int16, default: defaultMsg)
            UInt16: \(uint16, default: defaultMsg)
            Int32: \(int32, default: defaultMsg)
            UInt32: \(uint32, default: defaultMsg)
            Int64: \(int64, default: defaultMsg)
            UInt64: \(uint64, default: defaultMsg)
            Int: \(int, default: defaultMsg)
            UInt: \(uint, default: defaultMsg)
            Float: \(flt, default: defaultMsg)
            Double: \(dbl, default: defaultMsg)
            Bool: \(bool, default: defaultMsg)
            Date: \(date, default: defaultMsg)
            UUID: \(uuid, default: defaultMsg)
            IndexPath: \(indexPath, default: defaultMsg)
            Object: \(obj, default: defaultMsg)
            """
        let expectedFormat: String = """
            String: %@
            Substring: %@
            Int8: %c
            UInt8: %c
            Int16: %i
            UInt16: %u
            Int32: %li
            UInt32: %lu
            Int64: %lli
            UInt64: %llu
            Int: %lli
            UInt: %llu
            Float: %f
            Double: %lf
            Bool: %i
            Date: %@
            UUID: %@
            IndexPath: %@
            Object: %@
            """

        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, 19)
        guard format.args.count >= 19 else { return } // prevent crashes
        XCTAssertEqual(format.args[0] as? String, str)
        XCTAssertEqual(format.args[1] as? String, String(substr!))
        XCTAssertEqual(format.args[2] as? Int8, int8)
        XCTAssertEqual(format.args[3] as? UInt8, uint8)
        XCTAssertEqual(format.args[4] as? Int16, int16)
        XCTAssertEqual(format.args[5] as? UInt16, uint16)
        XCTAssertEqual(format.args[6] as? Int32, int32)
        XCTAssertEqual(format.args[7] as? UInt32, uint32)
        XCTAssertEqual(format.args[8] as? Int64, int64)
        XCTAssertEqual(format.args[9] as? UInt64, uint64)
        XCTAssertEqual(format.args[10] as? Int, int)
        XCTAssertEqual(format.args[11] as? UInt, uint)
        XCTAssertEqual(format.args[12] as? Float, flt)
        XCTAssertEqual(format.args[13] as? Double, dbl)
        XCTAssertEqual(format.args[14] as? Bool, bool)
        XCTAssertEqual((format.args[15] as? NSDate).map { $0 as Date }, date)
        XCTAssertEqual((format.args[16] as? NSUUID).map { $0 as UUID }, uuid)
        XCTAssertEqual((format.args[17] as? NSIndexPath).map { $0 as IndexPath }, indexPath)
        XCTAssertIdentical(format.args[18] as? NSObject, obj)

        let expectedArgs: [any CVarArg] = [
            str!,
            String(substr!),
            int8!,
            uint8!,
            int16!,
            uint16!,
            int32!,
            uint32!,
            int64!,
            uint64!,
            int!,
            uint!,
            flt!,
            dbl!,
            bool!,
            date! as NSDate,
            uuid! as NSUUID,
            indexPath! as NSIndexPath,
            obj! as NSObject,
        ]
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: expectedArgs))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: expectedArgs))
#endif
    }

    func testMessageFormatWithNilOptionalsAndDefaults() {
        let str: String? = nil
        let substr: Substring? = nil
        let int8: Int8? = nil
        let uint8: UInt8? = nil
        let int16: Int16? = nil
        let uint16: UInt16? = nil
        let int32: Int32? = nil
        let uint32: UInt32? = nil
        let int64: Int64? = nil
        let uint64: UInt64? = nil
        let int: Int? = nil
        let uint: UInt? = nil
        let flt: Float? = nil
        let dbl: Double? = nil
        let bool: Bool? = nil
        let date: Date? = nil
        let uuid: UUID? = nil
        let indexPath: IndexPath? = nil
        let obj: TestObject? = nil

        let format: DDLogMessageFormat = """
            String: \(str, default: "str WAS NIL")
            Substring: \(substr, default: "substr WAS NIL")
            Int8: \(int8, default: "int8 WAS NIL")
            UInt8: \(uint8, default: "uint8 WAS NIL")
            Int16: \(int16, default: "int16 WAS NIL")
            UInt16: \(uint16, default: "uint16 WAS NIL")
            Int32: \(int32, default: "int32 WAS NIL")
            UInt32: \(uint32, default: "uint32 WAS NIL")
            Int64: \(int64, default: "int64 WAS NIL")
            UInt64: \(uint64, default: "uint64 WAS NIL")
            Int: \(int, default: "int WAS NIL")
            UInt: \(uint, default: "uint WAS NIL")
            Float: \(flt, default: "flt WAS NIL")
            Double: \(dbl, default: "dbl WAS NIL")
            Bool: \(bool, default: "bool WAS NIL")
            Date: \(date, default: "date WAS NIL")
            UUID: \(uuid, default: "uuid WAS NIL")
            IndexPath: \(indexPath, default: "indexPath WAS NIL")
            Object: \(obj, default: "obj WAS NIL")
            """
        let expectedFormat: String = """
            String: %@
            Substring: %@
            Int8: %@
            UInt8: %@
            Int16: %@
            UInt16: %@
            Int32: %@
            UInt32: %@
            Int64: %@
            UInt64: %@
            Int: %@
            UInt: %@
            Float: %@
            Double: %@
            Bool: %@
            Date: %@
            UUID: %@
            IndexPath: %@
            Object: %@
            """
        let expectedArgs: [String] = [
            "str WAS NIL",
            "substr WAS NIL",
            "int8 WAS NIL",
            "uint8 WAS NIL",
            "int16 WAS NIL",
            "uint16 WAS NIL",
            "int32 WAS NIL",
            "uint32 WAS NIL",
            "int64 WAS NIL",
            "uint64 WAS NIL",
            "int WAS NIL",
            "uint WAS NIL",
            "flt WAS NIL",
            "dbl WAS NIL",
            "bool WAS NIL",
            "date WAS NIL",
            "uuid WAS NIL",
            "indexPath WAS NIL",
            "obj WAS NIL",
        ]

        XCTAssertTrue(format.storage.requiresArgumentParsing)
        XCTAssertEqual(format.format, expectedFormat)
        XCTAssertEqual(format.args.count, expectedArgs.count)
        guard format.args.count >= expectedArgs.count else { return } // prevent crashes
        zip(format.args, expectedArgs).forEach { arg, expected in
            XCTAssertEqual(arg as? String, expected)
        }
#if compiler(>=6.2)
        XCTAssertEqual(format.formatted, unsafe String(format: expectedFormat, arguments: expectedArgs))
#else
        XCTAssertEqual(format.formatted, String(format: expectedFormat, arguments: expectedArgs))
#endif
    }
}

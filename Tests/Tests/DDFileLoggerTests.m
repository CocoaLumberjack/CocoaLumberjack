// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2018, Deusty, LLC
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

#import <XCTest/XCTest.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#import "DDSampleFileManager.h"

static const DDLogLevel ddLogLevel = DDLogLevelAll;

@interface DDFileLoggerTests : XCTestCase {
    DDFileLogger *logger;
}

@end

@implementation DDFileLoggerTests

- (void)setUp {
    [super setUp];
    logger = [[DDFileLogger alloc] initWithLogFileManager:[[DDSampleFileManager alloc] initWithLogFileHeader:@"header"]];
}

- (void)tearDown {
    [super tearDown];

    for (NSString *logFilePaths in logger.logFileManager.unsortedLogFilePaths) {
        NSError *error = nil;
        XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:logFilePaths error:&error]);
        XCTAssertNil(error);
    }

    [DDLog removeAllLoggers];
}

- (void)testWrapping {
    __auto_type wrapped = [logger wrapWithBuffer];
    XCTAssert([wrapped.class isSubclassOfClass:NSProxy.class]);

    __auto_type wrapped2 = [wrapped wrapWithBuffer];
    XCTAssertEqual(wrapped2, wrapped);

    __auto_type unwrapped = [wrapped unwrapFromBuffer];
    XCTAssert([unwrapped.class isSubclassOfClass:DDFileLogger.class]);

    __auto_type unwrapped2 = [unwrapped unwrapFromBuffer];
    XCTAssertEqual(unwrapped2, unwrapped);
}

- (void)testWriteToFileUnbuffered {
    logger = [logger unwrapFromBuffer];
    [DDLog addLogger:logger];

    DDLogError(@"%@", @"error");
    DDLogWarn(@"%@", @"warn");
    DDLogInfo(@"%@", @"info");
    DDLogDebug(@"%@", @"debug");
    DDLogVerbose(@"%@", @"verbose");

    [DDLog flushLog];

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:logger.currentLogFileInfo.filePath options:NSDataReadingUncached error:&error];
    XCTAssertNil(error);

    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqual([contents componentsSeparatedByString:@"\n"].count, 5 + 2);
}

- (void)testWriteToFileBuffered {
    logger = [logger wrapWithBuffer];
    [DDLog addLogger:logger];

    DDLogError(@"%@", @"error");
    DDLogWarn(@"%@", @"warn");
    DDLogInfo(@"%@", @"info");
    DDLogDebug(@"%@", @"debug");
    DDLogVerbose(@"%@", @"verbose");

    [DDLog flushLog];

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:logger.currentLogFileInfo.filePath options:NSDataReadingUncached error:&error];
    XCTAssertNil(error);

    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqual([contents componentsSeparatedByString:@"\n"].count, 5 + 2);
}

@end

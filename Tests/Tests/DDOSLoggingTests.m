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

@interface DDOSLoggingTests : XCTestCase
@end

@implementation DDOSLoggingTests

- (void)setUp {
    [super setUp];
    [DDLog removeAllLoggers];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRegisterLogger {
    if(@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)) {
        DDOSLogger *logger = [DDOSLogger sharedInstance];
        [DDLog addLogger:logger];
        XCTAssertEqualObjects(logger.loggerName, @"cocoa.lumberjack.osLogger");
        XCTAssertEqualObjects(logger, DDLog.allLoggers[0]);
    } else {
        DDASLLogger *logger = [DDASLLogger sharedInstance];
        [DDLog addLogger:logger];
        XCTAssertEqualObjects(logger.loggerName, @"cocoa.lumberjack.aslLogger");
        XCTAssertEqualObjects(logger, DDLog.allLoggers[0]);
    }
}

@end

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

@import XCTest;
#import <CocoaLumberjack/DDLog.h>

@interface DDTestLogger : NSObject <DDLogger>
@end

@implementation DDTestLogger
@synthesize logFormatter;
- (void)logMessage:(nonnull DDLogMessage *)logMessage {}
@end

@interface DDLogTests : XCTestCase
@end


// The fact thath the DDLog is initialized using +initialize makes it a bit
// dificult to test as the state of the class might be hanging there when
// test examples are run in parallel. Trying to reset the DDLog before & after
// each test.
@implementation DDLogTests

- (void)setUp {
    [super setUp];
    [DDLog removeAllLoggers];
}

- (void)tearDown {
    [DDLog removeAllLoggers];
    [super tearDown];
}


#pragma mark - Logger management

- (void)testAddLoggerAddsNewLoggerWithDDLogLevelAll {
    __auto_type logger = [DDTestLogger new];
    [DDLog addLogger:logger];
    XCTAssertEqual([DDLog allLoggers].count, 1);
}

- (void)testAddLoggerWithLevelAddLoggerWithSpecifiedLevelMask {
    __auto_type logger = [DDTestLogger new];
    [DDLog addLogger:logger withLevel:DDLogLevelDebug | DDLogLevelError];
    XCTAssertEqual([DDLog allLoggers].count, 1);
}

- (void)testRemoveLoggerRemovesExistingLogger {
    __auto_type logger = [DDTestLogger new];
    [DDLog addLogger:logger];
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog removeLogger:logger];
    XCTAssertEqual([DDLog allLoggers].count, 1);
    XCTAssertFalse([[DDLog allLoggers] firstObject] == logger);
}

- (void)testRemoveAllLoggersRemovesAllLoggers {
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog removeAllLoggers];
    XCTAssertEqual([DDLog allLoggers].count, 0);
}

- (void)testAllLoggersReturnsAllLoggers {
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog addLogger:[DDTestLogger new]];
    XCTAssertEqual([DDLog allLoggers].count, 2);
}

- (void)testAllLoggersWithLevelReturnsAllLoggersWithLevel {
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog addLogger:[DDTestLogger new] withLevel:DDLogLevelDebug];
    [DDLog addLogger:[DDTestLogger new] withLevel:DDLogLevelInfo];
    XCTAssertEqual([DDLog allLoggersWithLevel].count, 3);
    XCTAssertEqual([[[DDLog allLoggersWithLevel] firstObject] level], DDLogLevelAll);
    XCTAssertEqual([[DDLog allLoggersWithLevel][1] level], DDLogLevelDebug);
    XCTAssertEqual([[DDLog allLoggersWithLevel][2] level], DDLogLevelInfo);
}

@end

// Software License Agreement (BSD License)
//
// Copyright (c) 2014-2016, Deusty, LLC
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
//
//  Created by Pavel Kunc on 18/04/2015.
//

@import XCTest;
#import <Expecta.h>
#import "DDLog.h"

@interface DDTestLogger : NSObject <DDLogger>
@end
@implementation DDTestLogger
@end

@interface DDLogTests : XCTestCase
@end


// The fact thath the DDLog is initialized using +initialize makes it a bit
// dificult to test as the state of the class might be hanging there when
// test examples are run in parallel. Trying to reset the DDLog before & after
// each test.
@implementation DDLogTests

- (void)setUp {
    [DDLog removeAllLoggers];
    [super setUp];
}

- (void)tearDown {
    [DDLog removeAllLoggers];
    [super tearDown];
}


#pragma mark - Logger management

- (void)testAddLoggerAddsNewLoggerWithDDLogLevelAll {
    DDTestLogger *logger = [DDTestLogger new];
    [DDLog addLogger:logger];
    expect([DDLog allLoggers]).haveACountOf(1);
}

- (void)testAddLoggerWithLevelAddLoggerWithSpecifiedLevelMask {
    DDTestLogger *logger = [DDTestLogger new];
    [DDLog addLogger:logger withLevel:DDLogLevelDebug | DDLogLevelError];
    expect([DDLog allLoggers]).haveACountOf(1);
}

- (void)testRemoveLoggerRemovesExistingLogger {
    DDTestLogger *logger = [DDTestLogger new];
    [DDLog addLogger:logger];
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog removeLogger:logger];
    expect([DDLog allLoggers]).haveACountOf(1);
    expect([[DDLog allLoggers] firstObject]).notTo.beIdenticalTo(logger);
}

- (void)testRemoveAllLoggersRemovesAllLoggers {
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog removeAllLoggers];
    expect([DDLog allLoggers]).to.beEmpty();
}

- (void)testAllLoggersReturnsAllLoggers {
    [DDLog addLogger:[DDTestLogger new]];
    [DDLog addLogger:[DDTestLogger new]];
    expect([DDLog allLoggers]).haveACountOf(2);
}

@end

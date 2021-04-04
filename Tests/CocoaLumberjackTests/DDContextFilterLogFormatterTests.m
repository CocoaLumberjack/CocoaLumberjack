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

#import <XCTest/XCTest.h>
#import <CocoaLumberjack/DDContextFilterLogFormatter.h>

static DDLogMessage *testLogMessage() {
    return [[DDLogMessage alloc] initWithMessage:@"test log message"
                                           level:DDLogLevelDebug
                                            flag:DDLogFlagError
                                         context:1
                                            file:@(__FILE__)
                                        function:@(__func__)
                                            line:__LINE__
                                             tag:NULL
                                         options:(DDLogMessageOptions)0
                                       timestamp:nil];
}

@interface DDContextAllowlistFilterLogFormatterTests : XCTestCase
@property (nonatomic, strong, readwrite) DDContextAllowlistFilterLogFormatter *filterLogFormatter;
@end

@implementation DDContextAllowlistFilterLogFormatterTests

- (void)setUp {
    [super setUp];
    self.filterLogFormatter = [[DDContextAllowlistFilterLogFormatter alloc] init];
}

- (void)tearDown {
    self.filterLogFormatter = nil;
    [super tearDown];
}

- (void)testAllowlistFilterLogFormatter {
    XCTAssertEqualObjects([self.filterLogFormatter allowlist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnAllowlist:1]);
    XCTAssertNil([self.filterLogFormatter formatLogMessage:testLogMessage()]);
    
    [self.filterLogFormatter addToAllowlist:1];
    XCTAssertEqualObjects([self.filterLogFormatter allowlist], @[@1]);
    XCTAssertTrue([self.filterLogFormatter isOnAllowlist:1]);
    XCTAssertEqualObjects([self.filterLogFormatter formatLogMessage:testLogMessage()], @"test log message");
    
    [self.filterLogFormatter removeFromAllowlist:1];
    XCTAssertEqualObjects([self.filterLogFormatter allowlist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnAllowlist:1]);
    XCTAssertNil([self.filterLogFormatter formatLogMessage:testLogMessage()]);
}

@end


@interface DDContextDenylistFilterLogFormatterTests : XCTestCase
@property (nonatomic, strong, readwrite) DDContextDenylistFilterLogFormatter *filterLogFormatter;
@end

@implementation DDContextDenylistFilterLogFormatterTests

- (void)setUp {
    [super setUp];
    self.filterLogFormatter = [[DDContextDenylistFilterLogFormatter alloc] init];
}

- (void)tearDown {
    self.filterLogFormatter = nil;
    [super tearDown];
}

- (void)testDDContextDenylistFilterLogFormatterTests {
    XCTAssertEqualObjects([self.filterLogFormatter denylist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnDenylist:1]);
    XCTAssertEqualObjects([self.filterLogFormatter formatLogMessage:testLogMessage()], @"test log message");
    
    [self.filterLogFormatter addToDenylist:1];
    XCTAssertEqualObjects([self.filterLogFormatter denylist], @[@1]);
    XCTAssertTrue([self.filterLogFormatter isOnDenylist:1]);
    XCTAssertNil([self.filterLogFormatter formatLogMessage:testLogMessage()]);
    
    [self.filterLogFormatter removeFromDenylist:1];
    XCTAssertEqualObjects([self.filterLogFormatter denylist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnDenylist:1]);
    XCTAssertEqualObjects([self.filterLogFormatter formatLogMessage:testLogMessage()], @"test log message");
}

@end

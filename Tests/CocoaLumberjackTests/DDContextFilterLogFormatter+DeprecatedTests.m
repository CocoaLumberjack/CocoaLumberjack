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
#import <CocoaLumberjack/DDContextFilterLogFormatter+Deprecated.h>

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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface DDContextWhitelistFilterLogFormatterTests : XCTestCase
@property (nonatomic, strong, readwrite) DDContextWhitelistFilterLogFormatter *filterLogFormatter;
@end

@implementation DDContextWhitelistFilterLogFormatterTests

- (void)setUp {
    [super setUp];
    self.filterLogFormatter = [[DDContextWhitelistFilterLogFormatter alloc] init];
}

- (void)tearDown {
    self.filterLogFormatter = nil;
    [super tearDown];
}

- (void)testWhitelistFilterLogFormatter {
    XCTAssertEqualObjects([self.filterLogFormatter whitelist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnWhitelist:1]);
    XCTAssertNil([self.filterLogFormatter formatLogMessage:testLogMessage()]);
    
    [self.filterLogFormatter addToWhitelist:1];
    XCTAssertEqualObjects([self.filterLogFormatter whitelist], @[@1]);
    XCTAssertTrue([self.filterLogFormatter isOnWhitelist:1]);
    XCTAssertEqualObjects([self.filterLogFormatter formatLogMessage:testLogMessage()], @"test log message");
    
    [self.filterLogFormatter removeFromWhitelist:1];
    XCTAssertEqualObjects([self.filterLogFormatter whitelist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnWhitelist:1]);
    XCTAssertNil([self.filterLogFormatter formatLogMessage:testLogMessage()]);
}

@end
#pragma clang diagnostic pop


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface DDContextBlacklistFilterLogFormatterTests : XCTestCase
@property (nonatomic, strong, readwrite) DDContextBlacklistFilterLogFormatter *filterLogFormatter;
@end

@implementation DDContextBlacklistFilterLogFormatterTests

- (void)setUp {
    [super setUp];
    self.filterLogFormatter = [[DDContextBlacklistFilterLogFormatter alloc] init];
}

- (void)tearDown {
    self.filterLogFormatter = nil;
    [super tearDown];
}

- (void)testDDContextBlacklistFilterLogFormatterTests {
    XCTAssertEqualObjects([self.filterLogFormatter blacklist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnBlacklist:1]);
    XCTAssertEqualObjects([self.filterLogFormatter formatLogMessage:testLogMessage()], @"test log message");
    
    [self.filterLogFormatter addToBlacklist:1];
    XCTAssertEqualObjects([self.filterLogFormatter blacklist], @[@1]);
    XCTAssertTrue([self.filterLogFormatter isOnBlacklist:1]);
    XCTAssertNil([self.filterLogFormatter formatLogMessage:testLogMessage()]);
    
    [self.filterLogFormatter removeFromBlacklist:1];
    XCTAssertEqualObjects([self.filterLogFormatter blacklist], @[]);
    XCTAssertFalse([self.filterLogFormatter isOnBlacklist:1]);
    XCTAssertEqualObjects([self.filterLogFormatter formatLogMessage:testLogMessage()], @"test log message");
}

@end
#pragma clang diagnostic pop

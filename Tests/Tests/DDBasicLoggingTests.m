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

@import XCTest;
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "DDSMocking.h"

const NSTimeInterval kAsyncExpectationTimeout = 3.0f;

static DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface DDBasicLoggingTests : XCTestCase

@property (nonatomic, strong) NSArray *logs;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) DDAbstractLogger *logger;
@property (nonatomic, assign) NSUInteger noOfMessagesLogged;

@end

@interface DDBasicMockAbstractLogger: DDAbstractLogger
@property (copy, nonatomic, readwrite) void(^block)(id object);
- (instancetype)configuredWithBlock:(void(^)(id object))block;
@end
@implementation DDBasicMockAbstractLogger
- (void)logMessage:(DDLogMessage *)logMessage {
    if (self.block) {
        self.block(logMessage);
    }
    else {
        [super logMessage:logMessage];
    }
}
- (instancetype)configuredWithBlock:(void (^)(id))block {
    self.block = block;
    return self;
}
@end

@implementation DDBasicLoggingTests

- (void)reactOnMessage:(id)object {
    __auto_type message = (DDLogMessage *)object;
    XCTAssertTrue([self.logs containsObject:message.message]);
    self.noOfMessagesLogged++;
    if (self.noOfMessagesLogged == [self.logs count]) {
        [self.expectation fulfill];
    }
}

- (void)cleanup {
    [DDLog removeAllLoggers];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:self.logger];
    
    ddLogLevel = DDLogLevelVerbose;
    
    self.logs = @[];
    self.expectation = nil;
    self.noOfMessagesLogged = 0;
}

- (void)_setUp {
    [super setUp];
    
    if (self.logger == nil) {
        __weak typeof(self) weakSelf = self;
        __auto_type logger = [[DDBasicMockAbstractLogger new] configuredWithBlock:^(id object) {
            [weakSelf reactOnMessage:object];
        }];
        self.logger = logger;
    }
    
    [self cleanup];
}

- (void)setUp {
    [super setUp];
    
    if (self.logger == nil) {
        __auto_type logger = [DDBasicMock<DDAbstractLogger *> decoratedInstance:[[DDAbstractLogger alloc] init]];

        __weak typeof(self)weakSelf = self;
        __auto_type argument = [DDBasicMockArgument alongsideWithBlock:^(id object) {
            [weakSelf reactOnMessage:object];
        }];
        
        [logger addArgument:argument forSelector:@selector(logMessage:) atIndex:2];
        
        self.logger = (DDAbstractLogger *)logger;
    }

    [self cleanup];
}

- (void)testAll5DefaultLevelsAsync {
    self.expectation = [self expectationWithDescription:@"default log levels"];
    self.logs = @[ @"Error", @"Warn", @"Info", @"Debug", @"Verbose" ];
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
}

- (void)testLoggerLogLevelAsync {
    self.expectation = [self expectationWithDescription:@"logger level"];
    self.logs = @[ @"Error", @"Warn" ];
    
    [DDLog removeLogger:self.logger];
    [DDLog addLogger:self.logger withLevel:DDLogLevelWarning];
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
}

- (void)testX_ddLogLevel_async {
    self.expectation = [self expectationWithDescription:@"ddLogLevel"];
    self.logs = @[ @"Error", @"Warn", @"Info" ];
    
    ddLogLevel = DDLogLevelInfo;
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
    
    ddLogLevel = DDLogLevelVerbose;
}

@end

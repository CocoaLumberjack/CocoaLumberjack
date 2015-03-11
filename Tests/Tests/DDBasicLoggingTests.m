// Software License Agreement (BSD License)
//
// Copyright (c) 2014-2015, Deusty, LLC
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
#import <CocoaLumberjack.h>
#import <OCMock.h>
#import <Expecta.h>

DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface DDBasicLoggingTests : XCTestCase

@end

@implementation DDBasicLoggingTests

- (void)setUp {
    [super setUp];
    [DDLog removeAllLoggers];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    ddLogLevel = DDLogLevelVerbose;
}

- (void)testAll5DefaultLevelsAsync {
    XCTestExpectation *expectation = [self expectationWithDescription:@"default log levels"];
    
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    
    __block int noOfMessagesLogged = 0;
    NSArray *logs = @[ @"Error", @"Warn", @"Info", @"Debug", @"Verbose" ];
    
    DDTTYLogger *ttyLoggerMock = OCMPartialMock(ttyLogger);
    OCMStub([ttyLoggerMock logMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
        DDLogMessage *message = (DDLogMessage *)obj;
        
        expect(logs).to.contain(message.message);
        
        noOfMessagesLogged++;
        if (noOfMessagesLogged == [logs count]) {
            [expectation fulfill];
        }
        return YES;
    }]]);
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *timeoutError) {
        expect(timeoutError).to.beNil();
    }];
}

- (void)testLoggerLogLevelAsync {
    XCTestExpectation *expectation = [self expectationWithDescription:@"logger level"];
    
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    
    [DDLog removeAllLoggers];
    [DDLog addLogger:ttyLogger withLevel:DDLogLevelWarning];
    
    __block int noOfMessagesLogged = 0;
    NSArray *logs = @[ @"Error", @"Warn" ];
    
    DDTTYLogger *ttyLoggerMock = OCMPartialMock(ttyLogger);
    OCMStub([ttyLoggerMock logMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
        DDLogMessage *message = (DDLogMessage *)obj;
        
        expect(logs).to.contain(message.message);
        
        noOfMessagesLogged++;
        if (noOfMessagesLogged == [logs count]) {
            [expectation fulfill];
        }
        return YES;
    }]]);
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *timeoutError) {
        expect(timeoutError).to.beNil();
    }];
}

- (void)test_ddLogLevel_async {
    XCTestExpectation *expectation = [self expectationWithDescription:@"ddLogLevel"];
    
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    
    ddLogLevel = DDLogLevelInfo;
    
    __block int noOfMessagesLogged = 0;
    NSArray *logs = @[ @"Error", @"Warn", @"Info" ];
    
    DDTTYLogger *ttyLoggerMock = OCMPartialMock(ttyLogger);
    OCMStub([ttyLoggerMock logMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
        DDLogMessage *message = (DDLogMessage *)obj;
        
        expect(logs).to.contain(message.message);
        
        noOfMessagesLogged++;
        if (noOfMessagesLogged == [logs count]) {
            [expectation fulfill];
        }
        return YES;
    }]]);
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *timeoutError) {
        expect(timeoutError).to.beNil();
    }];
    
    ddLogLevel = DDLogLevelVerbose;
}

@end

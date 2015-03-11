//
//  DDBasicLoggingTests.m
//  CocoaLumberjack Tests
//
//  Created by Bogdan on 09/03/15.
//  Copyright (c) 2015 deusty. All rights reserved.
//

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
    }]]).andForwardToRealObject();
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError *timeoutError) {
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
    }]]).andForwardToRealObject();
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError *timeoutError) {
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
    }]]).andForwardToRealObject();
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError *timeoutError) {
        expect(timeoutError).to.beNil();
    }];
}

@end

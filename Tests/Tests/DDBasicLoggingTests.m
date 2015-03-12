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


const NSTimeInterval kAsyncExpectationTimeout = 3.0f;

DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface DDBasicLoggingTests : XCTestCase

@property (nonatomic, strong) NSArray *logs;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) DDAbstractLogger *logger;
@property (nonatomic, assign) NSUInteger noOfMessagesLogged;

@end

@implementation DDBasicLoggingTests

- (void)setUp {
    [super setUp];
    
    if (self.logger == nil) {
        self.logger = OCMPartialMock([[DDAbstractLogger alloc] init]);
        
        __weak typeof(self)weakSelf = self;
        
        OCMStub([self.logger logMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            DDLogMessage *message = (DDLogMessage *)obj;
            
            expect(strongSelf.logs).to.contain(message.message);
            
            strongSelf.noOfMessagesLogged++;
            
            // NOTE: this method is called twice for every log (the second time if for getting the obj param)
            if (strongSelf.noOfMessagesLogged == 2 * [strongSelf.logs count]) {
                [self.expectation fulfill];
            }
            
            return YES;
        }]]);
    }
    
    [DDLog removeAllLoggers];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:self.logger];
    
    ddLogLevel = DDLogLevelVerbose;
    
    self.logs = @[];
    self.expectation = nil;
    self.noOfMessagesLogged = 0;
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
        expect(timeoutError).to.beNil();
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
        expect(timeoutError).to.beNil();
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
        expect(timeoutError).to.beNil();
    }];
    
    ddLogLevel = DDLogLevelVerbose;
}

@end

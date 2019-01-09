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

static const NSTimeInterval kAsyncExpectationTimeout = 3.0f;

static DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface DDBasicLoggingTests : XCTestCase
@property (nonatomic, strong) NSArray *logs;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) DDAbstractLogger *logger;
@property (nonatomic, assign) NSUInteger noOfMessagesLogged;
@end

@implementation DDBasicLoggingTests

- (void)reactOnMessage:(id)object {
    __auto_type message = (DDLogMessage *)object;
    XCTAssertTrue([self.logs containsObject:message.message]);
    XCTAssertEqualObjects(message.fileName, @"DDBasicLoggingTests");
    self.noOfMessagesLogged++;
    if (self.noOfMessagesLogged == [self.logs count]) {
        [self.expectation fulfill];
    }
}

- (DDBasicMock<DDAbstractLogger *> *)createAbstractLogger {
    __auto_type logger = [DDBasicMock<DDAbstractLogger *> decoratedInstance:[[DDAbstractLogger alloc] init]];
    
    __weak __auto_type weakSelf = self;
    __auto_type argument = [DDBasicMockArgument alongsideWithBlock:^(id object) {
        [weakSelf reactOnMessage:object];
    }];
    
    [logger addArgument:argument forSelector:@selector(logMessage:) atIndex:2];
    return logger;
}

- (void)setupLoggers {
    if (@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)) {
        [DDLog addLogger:[DDOSLogger new]];
    } else {
        [DDLog addLogger:[DDTTYLogger new]];
    }
    
    [DDLog addLogger:self.logger];
}

- (void)resetToDefaults {
    [DDLog removeAllLoggers];
    
    ddLogLevel = DDLogLevelVerbose;
    
    self.logs = @[];
    self.expectation = nil;
    self.noOfMessagesLogged = 0;
}

- (void)setUp {
    [super setUp];
    [self resetToDefaults];
    
    if (self.logger == nil) {
        __auto_type logger = [self createAbstractLogger];
        self.logger = (DDAbstractLogger *)logger;
    }
    
    [self setupLoggers];
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

- (void)testGlobalLogLevelAsync {
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

@interface DDBasicLoggingTests__MultiLoggers : DDBasicLoggingTests
@property (strong, nonatomic, readwrite) NSArray *loggers;
@property (assign, nonatomic, readwrite) NSUInteger countOfLoggers;
@end

@implementation DDBasicLoggingTests__MultiLoggers
- (void)setUp {
    self.countOfLoggers = 3;
    [super setUp];
}
- (void)setLogger:(DDAbstractLogger *)logger {
    return;
}

- (void)reactOnMessage:(id)object {
    __auto_type message = (DDLogMessage *)object;
    XCTAssertTrue([self.logs containsObject:message.message]);
    XCTAssertEqualObjects(message.fileName, @"DDBasicLoggingTests");
    self.noOfMessagesLogged++;
    if (self.noOfMessagesLogged == self.logs.count * self.loggers.count) {
        [self.expectation fulfill];
    }
}

- (void)setupLoggers {
    if (@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)) {
        [DDLog addLogger:[DDOSLogger new]];
    } else {
        [DDLog addLogger:[DDTTYLogger new]];
    }
    
    if (self.loggers.count == 0) {
        for (NSUInteger i = 0; i < self.countOfLoggers; ++i) {
            self.loggers = [self.loggers ?: @[] arrayByAddingObject:[self createAbstractLogger]];
        }
    }
    
    for (DDAbstractLogger *logger in self.loggers) {
        [DDLog addLogger:logger];
    }
}


- (void)testAll5DefaultLevelsAsync {
    self.expectation = [self expectationWithDescription:@"default log levels"];
    self.logs = @[ @"Error" ];
    
    DDLogError(@"Error");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
}
- (void)testLoggerLogLevelAsync {}
- (void)testGlobalLogLevelAsync {}
@end

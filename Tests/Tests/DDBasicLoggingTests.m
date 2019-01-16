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

static DDBasicMock<DDAbstractLogger *> *createAbstractLogger(void (^didLogBlock)(id)) {
    __auto_type logger = [DDBasicMock<DDAbstractLogger *> decoratedInstance:[[DDAbstractLogger alloc] init]];
    __auto_type argument = [DDBasicMockArgument alongsideWithBlock:didLogBlock];
    [logger addArgument:argument forSelector:@selector(logMessage:) atIndex:2];
    return logger;
}

@interface DDSingleLoggerLoggingTests : XCTestCase
@property (nonatomic, strong) NSArray *logs;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) DDAbstractLogger *logger;
@property (nonatomic, assign) NSUInteger numberMessagesLoged;
@property (nonatomic) dispatch_queue_t serial;
@end

@implementation DDSingleLoggerLoggingTests

- (void)setupLoggers {
    __weak __auto_type weakSelf = self;
    self.logger = (DDAbstractLogger *)createAbstractLogger(^(DDLogMessage *logMessage) {
        dispatch_sync(self->_serial, ^{
            __auto_type strongSelf = weakSelf;

            XCTAssertTrue([logMessage isKindOfClass:[DDLogMessage class]]);
            XCTAssertTrue([strongSelf.logs containsObject:logMessage.message]);
            XCTAssertEqualObjects(logMessage.fileName, @"DDBasicLoggingTests");

            strongSelf.numberMessagesLoged++;
            if (strongSelf.numberMessagesLoged == [strongSelf.logs count]) {
                [strongSelf.expectation fulfill];
            }
        });
    });

    [DDLog addLogger:self.logger];
}

- (void)resetToDefaults {
    [DDLog removeAllLoggers];
    
    ddLogLevel = DDLogLevelVerbose;
    
    self.logs = @[];
    self.expectation = nil;
    self.numberMessagesLoged = 0;
    self.serial = dispatch_queue_create("serial", NULL);
}

- (void)setUp {
    [super setUp];
    [self resetToDefaults];
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

    [DDLog flushLog];
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

    [DDLog flushLog];
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

    [DDLog flushLog];
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
    
    ddLogLevel = DDLogLevelVerbose;
}

@end

static int const DDLoggerCount = 3;

@interface DDMultipleLoggerLoggingTests : XCTestCase

@property (nonatomic) NSArray *loggers;
@property (nonatomic) NSArray *logs;

@property (nonatomic) XCTestExpectation *expectation;

@property (nonatomic) NSUInteger numberMessagesLoged;
@property (nonatomic) dispatch_queue_t serial;

@end

@implementation DDMultipleLoggerLoggingTests

- (void)reactOnMessage:(id)object {
    __auto_type message = (DDLogMessage *)object;

    XCTAssertTrue([self.logs containsObject:message.message]);
    XCTAssertEqualObjects(message.fileName, @"DDBasicLoggingTests");

    self.numberMessagesLoged++;
    if (self.numberMessagesLoged == self.logs.count * self.loggers.count) {
        [self.expectation fulfill];
    }
}

- (void)resetToDefaults {
    [DDLog removeAllLoggers];

    ddLogLevel = DDLogLevelVerbose;

    self.logs = @[];
    self.expectation = nil;
    self.numberMessagesLoged = 0;
    self.serial = dispatch_queue_create("serial", NULL);
}

- (void)setUp {
    [super setUp];
    [self resetToDefaults];
    [self setupLoggers];
}

- (void)setupLoggers {
    NSMutableArray *loggers = [NSMutableArray arrayWithCapacity:DDLoggerCount];

    for (NSUInteger i = 0; i < DDLoggerCount; i++) {
        __weak __auto_type weakSelf = self;
        __auto_type logger = (DDAbstractLogger *)createAbstractLogger(^(DDLogMessage *logMessage) {
            dispatch_sync(self->_serial, ^{
                __auto_type strongSelf = weakSelf;

                XCTAssertTrue([logMessage isKindOfClass:[DDLogMessage class]]);
                XCTAssertTrue([strongSelf.logs containsObject:logMessage.message]);
                XCTAssertEqualObjects(logMessage.fileName, @"DDBasicLoggingTests");

                strongSelf.numberMessagesLoged++;
                if (strongSelf.numberMessagesLoged == [strongSelf.logs count]) {
                    [strongSelf.expectation fulfill];
                }
            });
        });

        [loggers addObject:logger];
        [DDLog addLogger:logger];
    }

    self.loggers = [loggers copy];
}

- (void)testAll5DefaultLevelsAsync {
    self.expectation = [self expectationWithDescription:@"default log levels"];
    self.logs = @[ @"Error" ];
    
    DDLogError(@"Error");

    [DDLog flushLog];
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
}

@end

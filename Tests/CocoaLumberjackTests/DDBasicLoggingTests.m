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
#import <CocoaLumberjack/DDLogMacros.h>
#import <CocoaLumberjack/DDAbstractDatabaseLogger.h>

#import "DDSampleFileManager.h"
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
@property (nonatomic, assign) NSUInteger numberMessagesLogged;
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

            strongSelf.numberMessagesLogged++;
            if (strongSelf.numberMessagesLogged == [strongSelf.logs count]) {
                [strongSelf.expectation fulfill];
            }
        });
    });

    [DDLog addLogger:self.logger];
}

- (void)setUp {
    [super setUp];
    self.serial = dispatch_queue_create("serial", NULL);
    self.logs = @[];
    self.numberMessagesLogged = 0;
    ddLogLevel = DDLogLevelVerbose;
    [self setupLoggers];
}

- (void)tearDown {
    [DDLog removeAllLoggers];

    self.logger = nil;
    self.expectation = nil;

    [super tearDown];
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

@property (nonatomic) NSUInteger numberMessagesLogged;
@property (nonatomic) dispatch_queue_t serial;

@end

@implementation DDMultipleLoggerLoggingTests

- (void)setUp {
    [super setUp];
    self.serial = dispatch_queue_create("serial", NULL);
    self.logs = @[];
    self.numberMessagesLogged = 0;
    ddLogLevel = DDLogLevelVerbose;
    [self setupLoggers];
}

- (void)tearDown {
    [DDLog removeAllLoggers];
    self.loggers = nil;
    self.expectation = nil;
    [super tearDown];
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

                strongSelf.numberMessagesLogged++;
                if (strongSelf.numberMessagesLogged == [strongSelf.logs count]) {
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

@interface DDAbstractDatabaseLogger ()

- (void)destroySaveTimer;
- (void)updateAndResumeSaveTimer;
- (void)createSuspendedSaveTimer;

@end

@interface DDTestDatabaseLogger : DDAbstractDatabaseLogger

- (void)setUnsavedTime;
- (void)suspendSaveTimer;

@end

@implementation DDTestDatabaseLogger

- (void)setUnsavedTime
{
    _unsavedTime = dispatch_time(DISPATCH_TIME_NOW, 0);
}

- (void)suspendSaveTimer {
    if (_saveTimer != NULL && _saveTimerSuspended == 0) {
        dispatch_suspend(_saveTimer);
        _saveTimerSuspended = 1;
    }
}

@end

@interface DDAbstractDatabaseLoggerTests : XCTestCase

@property (nonatomic) DDTestDatabaseLogger *logger;

@end

@implementation DDAbstractDatabaseLoggerTests

- (void)setUp {
    [super setUp];
    self.logger = [[DDTestDatabaseLogger alloc] init];
}

- (void)tearDown {
    self.logger = nil;
    [super tearDown];
}

- (void)testDestroyDeactivatedSaveTimer {
    [self.logger createSuspendedSaveTimer];
    [self.logger destroySaveTimer];
}

- (void)testDestroyActivatedSaveTimer {
    [self.logger createSuspendedSaveTimer];
    [self.logger setUnsavedTime];
    [self.logger updateAndResumeSaveTimer];
    [self.logger destroySaveTimer];
}

- (void)testDestroySuspendedSaveTimer {
    [self.logger createSuspendedSaveTimer];
    [self.logger setUnsavedTime];
    [self.logger updateAndResumeSaveTimer];
    [self.logger suspendSaveTimer];
    [self.logger destroySaveTimer];
}

@end

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

#import <XCTest/XCTest.h>

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "DDSampleFileManager.h"

// Debug levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelWarning; // CONST

@interface DDFileLoggerPerformanceTests : XCTestCase

@property (nonatomic) DDFileLogger *logger;

@end

@implementation DDFileLoggerPerformanceTests

- (void)setUp {
    _logger = [[DDFileLogger alloc] initWithLogFileManager:[DDSampleFileManager new]];
    [DDLog addLogger:_logger];
}

- (void)tearDown {
    [DDLog removeAllLoggers];
}

- (void)testPerformanceNotPrinted {
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            // Log statements that will not be executed due to log level
            DDLogVerbose(@"testPerformanceNotPrinted - %lu", (unsigned long)i);
        }
    }];
}

- (void)testPerformanceAsyncPrint {
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            // Log statements that will be executed asynchronously
            DDLogWarn(@"testPerformanceAsyncPrint - %lu", (unsigned long)i);
        }
    }];
}

- (void)testPerformanceAsyncPrintBuffered {
    [DDLog removeAllLoggers];
    [DDLog addLogger:[_logger wrapWithBuffer]];

    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            // Log statements that will be executed asynchronously
            DDLogWarn(@"testPerformanceAsyncPrintBuffered - %lu", (unsigned long)i);
        }
    }];
}

- (void)testPerformanceSyncPrint {
    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            // Log statements that will be executed synchronously
            DDLogError(@"testPerformanceSyncPrint - %lu", (unsigned long)i);
        }
    }];
}

- (void)testPerformanceSyncPrintBuffered {
    [DDLog removeAllLoggers];
    [DDLog addLogger:[_logger wrapWithBuffer]];

    [self measureBlock:^{
        for (NSUInteger i = 0; i < 1000; i++) {
            // Log statements that will be executed asynchronously
            DDLogError(@"testPerformanceSyncPrintBuffered - %lu", (unsigned long)i);
        }
    }];
}

- (void)testPerformancePrintEvenSpread {
    [self measureBlock:^{
        // Even Spread:
        //
        // 25% - Not executed due to log level
        // 50% - Executed asynchronously
        // 25% - Executed synchronously

        NSString *fmt = @"testPerformancePrintEvenSpread - %lu";

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogError(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogWarn(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogInfo(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogVerbose(fmt, (unsigned long)i);
        }
    }];
}

- (void)testPerformancePrintEvenSpreadBuffered {
    [DDLog removeAllLoggers];
    [DDLog addLogger:[_logger wrapWithBuffer]];

    [self measureBlock:^{
        // Even Spread:
        //
        // 25% - Not executed due to log level
        // 50% - Executed asynchronously
        // 25% - Executed synchronously

        NSString *fmt = @"testPerformancePrintEvenSpreadBuffered - %lu";

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogError(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogWarn(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogInfo(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 250; i++) {
            DDLogVerbose(fmt, (unsigned long)i);
        }
    }];
}

- (void)testPerformanceCustomSpread {
    [self measureBlock:^{
        // Custom Spread

        NSString *fmt = @"testPerformanceCustomSpread - %lu";

        for (NSUInteger i = 0; i < 900; i++) {
            DDLogError(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 100; i++) {
            DDLogWarn(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 100; i++) {
            DDLogInfo(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 100; i++) {
            DDLogVerbose(fmt, (unsigned long)i);
        }
    }];
}

- (void)testPerformanceCustomSpreadBuffered {
    [DDLog removeAllLoggers];
    [DDLog addLogger:[_logger wrapWithBuffer]];

    [self measureBlock:^{
        // Custom Spread

        NSString *fmt = @"testPerformanceCustomSpreadBuffered - %lu";

        for (NSUInteger i = 0; i < 900; i++) {
            DDLogError(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 100; i++) {
            DDLogWarn(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 100; i++) {
            DDLogInfo(fmt, (unsigned long)i);
        }

        for (NSUInteger i = 0; i < 100; i++) {
            DDLogVerbose(fmt, (unsigned long)i);
        }
    }];
}

@end

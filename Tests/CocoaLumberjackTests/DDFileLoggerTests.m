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

#import <CocoaLumberjack/DDFileLogger.h>
#import <CocoaLumberjack/DDFileLogger+Buffering.h>
#import <CocoaLumberjack/DDLogMacros.h>

#import <sys/xattr.h>

#import "DDSampleFileManager.h"

static const DDLogLevel ddLogLevel = DDLogLevelAll;

@interface DDFileLoggerTests : XCTestCase {
    DDSampleFileManager *logFileManager;
    DDFileLogger *logger;
    NSString *logsDirectory;
}

@end

@implementation DDFileLoggerTests

- (void)setUp {
    [super setUp];
    logFileManager = [[DDSampleFileManager alloc] initWithLogFileHeader:@"header"];
    logger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    logsDirectory = logger.logFileManager.logsDirectory;
}

- (void)tearDown {
    [super tearDown];

    [DDLog removeAllLoggers];
    // We need to sync all involved queues to wait for the post-removal processing of the logger to finish before deleting the files.
    NSAssert(![self->logger isOnGlobalLoggingQueue], @"Trouble ahead!");
    dispatch_sync([DDLog loggingQueue], ^{
        NSAssert(![self->logger isOnInternalLoggerQueue], @"Trouble ahead!");
        dispatch_sync(self->logger.loggerQueue, ^{
            /* noop */
        });
    });

    NSError *error = nil;
    __auto_type contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:&error];
    XCTAssertNil(error);
    for (NSString *path in contents) {
        error = nil;
        XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:[logsDirectory stringByAppendingPathComponent:path] error:&error]);
        XCTAssertNil(error);
    }

    error = nil;
    XCTAssertTrue([[NSFileManager defaultManager] removeItemAtPath:logsDirectory error:&error]);
    XCTAssertNil(error);

    logger = nil;
    logsDirectory = nil;
}

- (void)testExplicitLogFileRolling {
    [DDLog addLogger:logger];
    DDLogError(@"Some log in the old file");
    __auto_type oldLogFileInfo = [logger currentLogFileInfo];
    __auto_type expectation = [self expectationWithDescription:@"Waiting for the log file to be rolled"];
    [logger rollLogFileWithCompletionBlock:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    __auto_type newLogFileInfo = [logger currentLogFileInfo];
    XCTAssertNotNil(oldLogFileInfo);
    XCTAssertNotNil(newLogFileInfo);
    XCTAssertNotEqualObjects(oldLogFileInfo.filePath, newLogFileInfo.filePath);
    XCTAssertEqualObjects(oldLogFileInfo.filePath, logFileManager.archivedLogFilePath);
    XCTAssertTrue(oldLogFileInfo.isArchived);
    XCTAssertFalse(newLogFileInfo.isArchived);
}

- (void)testExplicitLogFileRollingWhenNotReusingLogFiles {
    logger.doNotReuseLogFiles = YES;

    [DDLog addLogger:logger];
    DDLogError(@"Log 1 in the old file");
    DDLogError(@"Log 2 in the old file");
    __auto_type expectation = [self expectationWithDescription:@"Waiting for the log file to be rolled"];
    [logger rollLogFileWithCompletionBlock:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    DDLogError(@"Log 1 in the new file");
    DDLogError(@"Log 2 in the new file");

    XCTAssertEqual(logger.logFileManager.unsortedLogFileInfos.count, 2);
}

- (void)testAutomaticLogFileRollingWhenNotReusingLogFiles {
    DDFileLogger *newLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    newLogger.doNotReuseLogFiles = YES;

    [DDLog addLogger:logger];
    DDLogError(@"Some log in the old file");
    __auto_type oldLogFileInfo = [logger currentLogFileInfo];
    __auto_type newLogFileInfo = [newLogger currentLogFileInfo];
    XCTAssertNotNil(oldLogFileInfo);
    XCTAssertNotNil(newLogFileInfo);
    XCTAssertNotEqualObjects(oldLogFileInfo.filePath, newLogFileInfo.filePath);
    XCTAssertEqualObjects(oldLogFileInfo.filePath, logFileManager.archivedLogFilePath);
    XCTAssertTrue(oldLogFileInfo.isArchived);
    XCTAssertFalse(newLogFileInfo.isArchived);
}

- (void)testCurrentLogFileInfoWhenNotReusingLogFilesOnlyCreatesNewLogFilesIfNecessary {
    logger.doNotReuseLogFiles = YES;

    __auto_type info1 = logger.currentLogFileInfo;
    __auto_type info2 = logger.currentLogFileInfo;
    XCTAssertEqualObjects(info1.filePath, info2.filePath);

    info1.isArchived = YES;

    __auto_type info3 = logger.currentLogFileInfo;
    __auto_type info4 = logger.currentLogFileInfo;
    XCTAssertEqualObjects(info3.filePath, info4.filePath);
    XCTAssertNotEqualObjects(info2.filePath, info3.filePath);

    XCTAssertEqual(logger.logFileManager.unsortedLogFileInfos.count, 2);
}

- (void)testExtendedAttributes {
    logger.doNotReuseLogFiles = YES;

    __auto_type info = logger.currentLogFileInfo;

    char buffer[1];
    ssize_t result = getxattr([info.filePath fileSystemRepresentation], "lumberjack.log.archived", buffer, 1, 0, 0);
    XCTAssertLessThan(result, 0);
    XCTAssertEqual(errno, ENOATTR);

    info.isArchived = YES;
    XCTAssertTrue(info.isArchived);

    result = getxattr([info.filePath fileSystemRepresentation], "lumberjack.log.archived", buffer, 1, 0, 0);
    XCTAssertEqual(result, 1);
    XCTAssertEqual(buffer[0], 0x01);

    info.isArchived = NO;
    XCTAssertFalse(info.isArchived);

    result = getxattr([info.filePath fileSystemRepresentation], "lumberjack.log.archived", buffer, 1, 0, 0);
    XCTAssertLessThan(result, 0);
    XCTAssertEqual(errno, ENOATTR);
}

- (void)testExtendedAttributesBackwardCompatibility {
    logger.doNotReuseLogFiles = YES;

    __auto_type info = logger.currentLogFileInfo;

    char buffer[1];
#if TARGET_IPHONE_SIMULATOR
    [info renameFile:@"dummy.archived.log"];

    XCTAssertTrue(info.isArchived);

    ssize_t result = getxattr([info.filePath fileSystemRepresentation], "lumberjack.log.archived", buffer, 1, 0, 0);
    XCTAssertEqual(result, 1);
    XCTAssertEqual(buffer[0], 0x01);
    XCTAssertEqualObjects(info.fileName, @"dummy.log");

    [info renameFile:@"dummy.archived.log"];

    info.isArchived = YES;
    XCTAssertTrue(info.isArchived);
    XCTAssertEqualObjects(info.fileName, @"dummy.log");

    [info renameFile:@"dummy.archived.log"];

    info.isArchived = NO;
    XCTAssertFalse(info.isArchived);
    XCTAssertEqualObjects(info.fileName, @"dummy.log");
#else
    int err = setxattr([info.filePath fileSystemRepresentation], "lumberjack.log.archived", "", 0, 0, 0);
    XCTAssertEqual(err, 0);

    XCTAssertTrue(info.isArchived);

    ssize_t result = getxattr([info.filePath fileSystemRepresentation], "lumberjack.log.archived", buffer, 1, 0, 0);
    XCTAssertEqual(result, 1);
    XCTAssertEqual(buffer[0], 0x01);
#endif
}

- (void)testMaximumNumberOfLogFiles {
    logger.doNotReuseLogFiles = YES;
    logger.logFileManager.maximumNumberOfLogFiles = 4;
    logger.maximumFileSize = 10;
    [DDLog addLogger:logger];
    DDLogError(@"Log 1 in the file");
    DDLogError(@"Log 2 in the file");
    DDLogError(@"Log 3 in the file");
    DDLogError(@"Log 4 in the file");
    
    /// wait log queue finish.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray *oldFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self->logger.logFileManager.logsDirectory error:nil];
        XCTAssertEqual(oldFileNames.count, 4);
        
        self->logger.logFileManager.maximumNumberOfLogFiles = 2;
        
        /// wait delete old files finish.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray *newFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self->logger.logFileManager.logsDirectory error:nil];
            XCTAssertEqual(newFileNames.count, 2);
        });
    });
}

- (void)testWrapping {
    __auto_type wrapped = [logger wrapWithBuffer];
    XCTAssert([wrapped.class isSubclassOfClass:NSProxy.class]);

    __auto_type wrapped2 = [wrapped wrapWithBuffer];
    XCTAssertEqual(wrapped2, wrapped);

    __auto_type unwrapped = [wrapped unwrapFromBuffer];
    XCTAssert([unwrapped.class isSubclassOfClass:DDFileLogger.class]);

    __auto_type unwrapped2 = [unwrapped unwrapFromBuffer];
    XCTAssertEqual(unwrapped2, unwrapped);
}

- (void)testWriteToFileUnbuffered {
    logger = [logger unwrapFromBuffer];
    [DDLog addLogger:logger];

    DDLogError(@"%@", @"error");
    DDLogWarn(@"%@", @"warn");
    DDLogInfo(@"%@", @"info");
    DDLogDebug(@"%@", @"debug");
    DDLogVerbose(@"%@", @"verbose");

    [DDLog flushLog];

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:logger.currentLogFileInfo.filePath options:NSDataReadingUncached error:&error];
    XCTAssertNil(error);

    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqual([contents componentsSeparatedByString:@"\n"].count, 5 + 2);
}

- (void)testWriteToFileBuffered {
    logger = [logger wrapWithBuffer];
    [DDLog addLogger:logger];

    DDLogError(@"%@", @"error");
    DDLogWarn(@"%@", @"warn");
    DDLogInfo(@"%@", @"info");
    DDLogDebug(@"%@", @"debug");
    DDLogVerbose(@"%@", @"verbose");

    [DDLog flushLog];

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:logger.currentLogFileInfo.filePath options:NSDataReadingUncached error:&error];
    XCTAssertNil(error);

    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqual([contents componentsSeparatedByString:@"\n"].count, 5 + 2);
}

@end

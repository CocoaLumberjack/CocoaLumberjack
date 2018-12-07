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


#pragma mark Test Case for DDLogFileManagerDefault
// Feel free to extend :-)

@interface DDLogFileManagerDefaultTests : XCTestCase
@property (nonatomic, strong, readwrite) DDLogFileManagerDefault *logFileManager;
@end

@implementation DDLogFileManagerDefaultTests

- (void)setUp {
    [super setUp];
    [self setUpLogFileManager];
}

- (void)setUpLogFileManager {
    NSString *logsDirectory = NSTemporaryDirectory();
    self.logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logsDirectory];
}

- (void)tearDown {
    self.logFileManager = nil;
    [super tearDown];
}

- (void)deleteLogFile:(NSString *)filePath {
    NSError *error = nil;
    if ([[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
        // file was deleted
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    }
    else {
        XCTFail("Log file was not deleted!");
    }
}

- (void)testCreateNewLogFile {
    NSString *filePath = [self.logFileManager createNewLogFile];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self deleteLogFile:filePath];
    }
    else {
        XCTFail("Log file was not created!");
    }
}

- (void)testCreateNewLogFileAssertEmpty {
    NSString *filePath = [self.logFileManager createNewLogFile];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        // check that log file is created empty
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] unsignedLongLongValue];
        XCTAssertEqual(fileSize, 0);

        [self deleteLogFile:filePath];
    }
    else {
        XCTFail("Log file was not created!");
    }
}

@end


#pragma mark Test Case for DDLogFileManagerOverride

@interface DDLogFileManagerOverride : DDLogFileManagerDefault
@end

@implementation DDLogFileManagerOverride
- (NSString *)logFileHeader {
    return @"This is a test!";
}
@end


@interface DDLogFileManagerOverrideTests : XCTestCase
@property (nonatomic, strong, readwrite) DDLogFileManagerOverride *logFileManager;
@end

@implementation DDLogFileManagerOverrideTests

- (void)setUp {
    [super setUp];
    [self setUpLogFileManager];
}

- (void)setUpLogFileManager {
    NSString *logsDirectory = NSTemporaryDirectory();
    self.logFileManager = [[DDLogFileManagerOverride alloc] initWithLogsDirectory:logsDirectory];
}

- (void)tearDown {
    self.logFileManager = nil;
    [super tearDown];
}

- (void)deleteLogFile:(NSString *)filePath {
    NSError *error = nil;
    if ([[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
        // file was deleted
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    }
    else {
        XCTFail("Log file was not deleted!");
    }
}

- (void)testCreateNewLogFileAssertCorrectContents {
    NSString *filePath = [self.logFileManager createNewLogFile];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        // check that log file is _not_ created empty
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] unsignedLongLongValue];
        XCTAssertNotEqual(fileSize, 0);
        
        // check that initial contents is equal to input text
        NSString *strToFile = [NSString stringWithFormat:@"%@\n", [self.logFileManager logFileHeader]];
        NSString *strFromFile = [NSString  stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if(![strFromFile isEqualToString: strToFile]) {
            XCTFail("Log file contents is incorrect!");
        }
        
        [self deleteLogFile:filePath];
    }
    else {
        XCTFail("Log file was not created!");
    }
}

//- (void)testCreateNewLogFileWithNewLogFileName {
//}

@end


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

#import "DDSampleFileManager.h"

#pragma mark DDLogFileManagerDefault

@interface DDLogFileManagerDefaultTests : XCTestCase
@property (nonatomic, strong, readwrite) DDLogFileManagerDefault *logFileManager;
@end

@implementation DDLogFileManagerDefaultTests

- (void)setUp {
    [super setUp];
    [self setUpLogFileManager];
}

- (void)tearDown {
    [super tearDown];
    self.logFileManager = nil;
}

- (void)setUpLogFileManager {
    self.logFileManager = [[DDSampleFileManager alloc] initWithLogFileHeader:@"header"];
}

- (void)testCreateNewLogFile {
    __autoreleasing NSError *creationError;
    NSString *filePath = [self.logFileManager createNewLogFileWithError:&creationError];
    XCTAssertNil(creationError);
    XCTAssertTrue([self.logFileManager isLogFile:[NSURL fileURLWithPath:filePath].lastPathComponent]);

    __autoreleasing NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:&error];
    XCTAssertNil(error);

    XCTAssertEqualObjects([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], @"header\n");
}

@end


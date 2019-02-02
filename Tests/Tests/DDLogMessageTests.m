// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2019, Deusty, LLC
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

static NSString * const kDefaultMessage = @"Log message";

@interface DDLogMessage (TestHelpers)
+ (DDLogMessage *)test_message;
+ (DDLogMessage *)test_messageWithMessage:(NSString *)message;
+ (DDLogMessage *)test_messageWithFunction:(NSString *)function options:(DDLogMessageOptions)options;
+ (DDLogMessage *)test_messageWithFile:(NSString *)file options:(DDLogMessageOptions)options;
@end

@implementation DDLogMessage (TestHelpers)
+ (DDLogMessage *)test_message {
    return [[DDLogMessage alloc] initWithMessage:kDefaultMessage
                                           level:DDLogLevelDebug
                                            flag:DDLogFlagError
                                         context:1
                                            file:@(__FILE__)
                                        function:@(__func__)
                                            line:__LINE__
                                             tag:NULL
                                         options:(DDLogMessageOptions)0
                                       timestamp:nil];
}

+ (DDLogMessage *)test_messageWithMessage:(NSString *)message {
    return [[DDLogMessage alloc] initWithMessage:message
                                           level:DDLogLevelDebug
                                            flag:DDLogFlagError
                                         context:1
                                            file:@(__FILE__)
                                        function:@(__func__)
                                            line:__LINE__
                                             tag:NULL
                                         options:(DDLogMessageOptions)0
                                       timestamp:nil];
}

+ (DDLogMessage *)test_messageWithFunction:(NSString *)function
                                   options:(DDLogMessageOptions)options {
    return [[DDLogMessage alloc] initWithMessage:kDefaultMessage
                                           level:DDLogLevelDebug
                                            flag:DDLogFlagError
                                         context:1
                                            file:@(__FILE__)
                                        function:function
                                            line:__LINE__
                                             tag:NULL
                                         options:options
                                       timestamp:nil];
}

+ (DDLogMessage *)test_messageWithFile:(NSString *)file
                               options:(DDLogMessageOptions)options {
    return [[DDLogMessage alloc] initWithMessage:kDefaultMessage
                                           level:DDLogLevelDebug
                                            flag:DDLogFlagError
                                         context:1
                                            file:file
                                        function:@(__func__)
                                            line:__LINE__
                                             tag:NULL
                                         options:options
                                       timestamp:nil];
}

+ (DDLogMessage *)test_messageWithTimestamp:(NSDate *)timestamp {
    return [[DDLogMessage alloc] initWithMessage:kDefaultMessage
                                           level:DDLogLevelDebug
                                            flag:DDLogFlagError
                                         context:1
                                            file:@(__FILE__)
                                        function:@(__func__)
                                            line:__LINE__
                                             tag:NULL
                                         options:(DDLogMessageOptions)0
                                       timestamp:timestamp];
}

@end


@interface DDLogMessageTests : XCTestCase
@property (nonatomic, strong, readwrite) DDLogMessage *message;
@end

@implementation DDLogMessageTests

- (void)setUp {
    [super setUp];
    self.message = [DDLogMessage test_message];
}

- (void)tearDown {
    [super tearDown];
    self.message = nil;
}

#pragma mark - Message creation

- (void)testInitSetsAllPassedParameters {
    __auto_type referenceDate = [NSDate dateWithTimeIntervalSince1970:0];
    self.message =
        [[DDLogMessage alloc] initWithMessage:kDefaultMessage
                                        level:DDLogLevelDebug
                                         flag:DDLogFlagError
                                      context:1
                                         file:@"DDLogMessageTests.m"
                                     function:@"testInitSetsAllPassedParameters"
                                         line:50
                                          tag:NULL
                                         options:DDLogMessageCopyFile
                                         timestamp:referenceDate];
    XCTAssertEqualObjects(self.message.message, @"Log message");
    XCTAssertEqual(self.message.level, DDLogLevelDebug);
    XCTAssertEqual(self.message.flag, DDLogFlagError);
    XCTAssertEqual(self.message.context, 1);
    XCTAssertEqualObjects(self.message.file, @"DDLogMessageTests.m");
    XCTAssertEqualObjects(self.message.function, @"testInitSetsAllPassedParameters");
    XCTAssertEqual(self.message.line, 50);
    XCTAssertEqualObjects(self.message.tag, NULL);
    XCTAssertEqual(self.message.options, DDLogMessageCopyFile);
    XCTAssertEqualObjects(self.message.timestamp, referenceDate);
}

- (void)testInitCopyMessageParameter {
    __auto_type message = [NSMutableString stringWithString:@"Log message"];
    self.message = [DDLogMessage test_messageWithMessage:message];
    [message appendString:@" changed"];
    XCTAssertEqualObjects(self.message.message, @"Log message");
}

- (void)testInitSetsCurrentDateToTimestampIfItIsNotProvided {
    XCTAssertLessThanOrEqual(fabs([self.message.timestamp timeIntervalSinceNow]), 5);
}

- (void)testInitSetsThreadIDToCurrentThreadID {
    XCTAssertNotNil(self.message.threadID);
}

- (void)testInitSetsThreadNameToCurrentThreadName {
    XCTAssertEqualObjects(self.message.threadName, NSThread.currentThread.name);
}

- (void)testInitSetsFileNameToFilenameWithoutExtensionIfItHasExtension {
    XCTAssertEqualObjects(self.message.fileName, @"DDLogMessageTests");
}

- (void)testInitSetsFileNameToFilenameIfItHasNotExtension {
    self.message = [DDLogMessage test_messageWithFile:@"no-extenstion" options:(DDLogMessageOptions)0];
    XCTAssertEqualObjects(self.message.fileName, @"no-extenstion");
}

//TODO: How to test this for different SDK versions? (pavel, Sat 18 Apr 15:35:46 2015)
- (void)testInitSetsQueueLabelToQueueWeCurrentlyRun {
    // We're running on main thread
    XCTAssertEqualObjects(self.message.queueLabel, @"com.apple.main-thread");
}

- (void)testInitAssignsFileParameterWithoutCopyFileOption {
    __auto_type file = [NSMutableString stringWithString:@"file"];
    self.message = [DDLogMessage test_messageWithFile:file options:(DDLogMessageOptions)0];
    XCTAssertEqualObjects(self.message.file, @"file");
    [file appendString:@"file"];
    XCTAssertEqualObjects(self.message.file, @"filefile");
}

- (void)testInitCopyFileParameterWithCopyFileOption {
    __auto_type file = [NSMutableString stringWithString:@"file"];
    self.message = [DDLogMessage test_messageWithFile:file options:DDLogMessageCopyFile];
    XCTAssertEqualObjects(self.message.file, @"file");
    [file appendString:@"file"];
    XCTAssertEqualObjects(self.message.file, @"file");
}

- (void)testInitAssignFunctionParameterWithoutCopyFunctionOption {
    __auto_type function = [NSMutableString stringWithString:@"function"];
    self.message = [DDLogMessage test_messageWithFunction:function options:(DDLogMessageOptions)0];
    XCTAssertEqualObjects(self.message.function, @"function");
    [function appendString:@"function"];
    XCTAssertEqualObjects(self.message.function, @"functionfunction");
}

- (void)testInitCopyFunctionParameterWithCopyFunctionOption {
    __auto_type function = [NSMutableString stringWithString:@"function"];
    self.message = [DDLogMessage test_messageWithFunction:function options:DDLogMessageCopyFunction];
    XCTAssertEqualObjects(self.message.function, @"function");
    [function appendString:@"function"];
    XCTAssertEqualObjects(self.message.function, @"function");
}

- (void)testCopyWithZoneCreatesValidCopy {
    __auto_type copy = (typeof(self.message))[self.message copy];
    XCTAssertEqualObjects(self.message.message, copy.message);
    XCTAssertEqual(self.message.level, copy.level);
    XCTAssertEqual(self.message.flag, copy.flag);
    XCTAssertEqual(self.message.context, copy.context);
    XCTAssertEqualObjects(self.message.file, copy.file);
    XCTAssertEqualObjects(self.message.fileName, copy.fileName);
    XCTAssertEqualObjects(self.message.function, copy.function);
    XCTAssertEqual(self.message.line, copy.line);
    XCTAssertEqualObjects(self.message.tag, copy.tag);
    XCTAssertEqual(self.message.options, copy.options);
    XCTAssertEqualObjects(self.message.timestamp, copy.timestamp);
    XCTAssertEqualObjects(self.message.threadID, copy.threadID);
    XCTAssertEqualObjects(self.message.threadName, copy.threadName);
    XCTAssertEqualObjects(self.message.queueLabel, copy.queueLabel);
}

@end

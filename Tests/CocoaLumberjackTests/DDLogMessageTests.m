// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2025, Deusty, LLC
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
#import <sys/qos.h>

static NSString * const kDefaultMessage = @"Log message";

@interface DDLogMessage (TestHelpers)
- (instancetype)initWithNoArgsMessage:(NSString *)message
                                level:(DDLogLevel)level
                                 flag:(DDLogFlag)flag
                              context:(NSInteger)context
                                 file:(NSString *)file
                             function:(nullable NSString *)function
                                 line:(NSUInteger)line
                                  tag:(nullable id)tag
                              options:(DDLogMessageOptions)options
                            timestamp:(nullable NSDate *)timestamp;
+ (instancetype)test_message;
+ (instancetype)test_messageWithMessage:(NSString *)message;
+ (instancetype)test_messageWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (instancetype)test_messageWithFunction:(NSString *)function options:(DDLogMessageOptions)options;
+ (instancetype)test_messageWithFile:(NSString *)file options:(DDLogMessageOptions)options;
@end

@implementation DDLogMessage (TestHelpers)
- (instancetype)initWithNoArgsMessage:(NSString *)message
                                level:(DDLogLevel)level
                                 flag:(DDLogFlag)flag
                              context:(NSInteger)context
                                 file:(NSString *)file
                             function:(nullable NSString *)function
                                 line:(NSUInteger)line
                                  tag:(nullable id)tag
                              options:(DDLogMessageOptions)options
                            timestamp:(nullable NSDate *)timestamp {
    self = [self initWithFormat:message
                      formatted:message
                          level:level
                           flag:flag
                        context:context
                           file:file
                       function:function
                           line:line
                            tag:tag
                        options:options
                      timestamp:timestamp];
    return self;
}

+ (instancetype)test_message {
    return [[DDLogMessage alloc] initWithNoArgsMessage:kDefaultMessage
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

+ (instancetype)test_messageWithMessage:(NSString *)message {
    return [[DDLogMessage alloc] initWithNoArgsMessage:message
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

+ (instancetype)test_messageWithFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    __auto_type msg = [[DDLogMessage alloc] initWithFormat:format
                                                      args:args
                                                     level:DDLogLevelDebug
                                                      flag:DDLogFlagError
                                                   context:1
                                                      file:@(__FILE__)
                                                  function:@(__func__)
                                                      line:__LINE__
                                                       tag:NULL
                                                   options:(DDLogMessageOptions)0
                                                 timestamp:nil];
    va_end(args);
    return msg;
}

+ (instancetype)test_messageWithFunction:(NSString *)function
                                 options:(DDLogMessageOptions)options {
    return [[DDLogMessage alloc] initWithNoArgsMessage:kDefaultMessage
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

+ (instancetype)test_messageWithWithoutFunction {
    return [[DDLogMessage alloc] initWithNoArgsMessage:kDefaultMessage
                                                 level:DDLogLevelDebug
                                                  flag:DDLogFlagError
                                               context:1
                                                  file:@(__FILE__)
                                              function:nil
                                                  line:__LINE__
                                                   tag:NULL
                                               options:(DDLogMessageOptions)0
                                             timestamp:nil];
}

+ (instancetype)test_messageWithFile:(NSString *)file
                             options:(DDLogMessageOptions)options {
    return [[DDLogMessage alloc] initWithNoArgsMessage:kDefaultMessage
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

+ (instancetype)test_messageWithTimestamp:(NSDate *)timestamp {
    return [[DDLogMessage alloc] initWithNoArgsMessage:kDefaultMessage
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
    self.message = [[DDLogMessage alloc] initWithNoArgsMessage:kDefaultMessage
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
    XCTAssertEqualObjects(self.message.representedObject, NULL);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqualObjects(self.message.tag, NULL);
#pragma clang diagnostic pop
    XCTAssertEqual(self.message.options, DDLogMessageCopyFile);
    XCTAssertEqualObjects(self.message.timestamp, referenceDate);
}

- (void)testFormatPreserved {
    self.message = [DDLogMessage test_messageWithFormat:@"Formatted with this %@ and this %d", @"Arg1", 42];
    XCTAssertEqualObjects(self.message.message, @"Formatted with this Arg1 and this 42");
    XCTAssertEqualObjects(self.message.messageFormat, @"Formatted with this %@ and this %d");
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

- (void)testInitSetsThreadQOSToCurrentThreadQOS {
    XCTAssertEqual(self.message.qos, qos_class_self());
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
    XCTAssertEqualObjects(self.message.messageFormat, copy.messageFormat);
    XCTAssertEqualObjects(self.message.message, copy.message);
    XCTAssertEqual(self.message.level, copy.level);
    XCTAssertEqual(self.message.flag, copy.flag);
    XCTAssertEqual(self.message.context, copy.context);
    XCTAssertEqualObjects(self.message.file, copy.file);
    XCTAssertEqualObjects(self.message.fileName, copy.fileName);
    XCTAssertEqualObjects(self.message.function, copy.function);
    XCTAssertEqual(self.message.line, copy.line);
    XCTAssertEqualObjects(self.message.representedObject, copy.representedObject);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqualObjects(self.message.tag, copy.tag);
#pragma clang diagnostic pop
    XCTAssertEqual(self.message.options, copy.options);
    XCTAssertEqualObjects(self.message.timestamp, copy.timestamp);
    XCTAssertEqualObjects(self.message.threadID, copy.threadID);
    XCTAssertEqualObjects(self.message.threadName, copy.threadName);
    XCTAssertEqualObjects(self.message.queueLabel, copy.queueLabel);
    XCTAssertEqual(self.message.qos, copy.qos);
    XCTAssertEqual(self.message.hash, copy.hash);
    XCTAssertEqualObjects(self.message, copy);
}

- (void)testEqualityCopyWithoutFunction {
    __auto_type message = [DDLogMessage test_messageWithWithoutFunction];
    __auto_type copy = (typeof(message))[message copy];
    XCTAssertEqual(message.hash, copy.hash);
    XCTAssertEqualObjects(message, copy);
}

@end

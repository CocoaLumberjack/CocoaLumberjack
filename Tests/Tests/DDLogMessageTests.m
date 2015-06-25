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
//
//  Created by Pavel Kunc on 18/04/2015.
//

@import XCTest;
#import <Expecta.h>
#import "DDLog.h"

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
    NSDate *referenceDate  = [NSDate dateWithTimeIntervalSince1970:0];
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

    expect(self.message.message).to.equal(@"Log message");
    expect(self.message.level).to.equal(DDLogLevelDebug);
    expect(self.message.flag).to.equal(DDLogFlagError);
    expect(self.message.context).to.equal(1);
    expect(self.message.file).to.equal(@"DDLogMessageTests.m");
    expect(self.message.function).to.equal(@"testInitSetsAllPassedParameters");
    expect(self.message.line).to.equal(50);
    expect(self.message.tag).to.equal(NULL);
    expect(self.message.options).to.equal(DDLogMessageCopyFile);
    expect(self.message.timestamp).to.equal(referenceDate);
}

- (void)testInitCopyMessageParameter {
    NSMutableString *message = [NSMutableString stringWithString:@"Log message"];
    self.message = [DDLogMessage test_messageWithMessage:message];
    [message appendString:@" changed"];
    expect(self.message.message).to.equal(@"Log message");
}

- (void)testInitSetsCurrentDateToTimestampIfItIsNotProvided {
    expect(fabs([self.message.timestamp timeIntervalSinceNow])).to.beLessThanOrEqualTo(5);
}

- (void)testInitSetsThreadIDToCurrentThreadID {
    expect(self.message.threadID).notTo.beNil();
}

- (void)testInitSetsThreadNameToCurrentThreadName {
    expect(self.message.threadName).to.equal(NSThread.currentThread.name);
}

- (void)testInitSetsFileNameToFilenameWithoutExtensionIfItHasExtension {
    expect(self.message.fileName).to.equal(@"DDLogMessageTests");
}

- (void)testInitSetsFileNameToFilenameIfItHasNotExtension {
    self.message = [DDLogMessage test_messageWithFile:@"no-extenstion" options:(DDLogMessageOptions)0];
    expect(self.message.fileName).to.equal(@"no-extenstion");
}

//TODO: How to test this for different SDK versions? (pavel, Sat 18 Apr 15:35:46 2015)
- (void)testInitSetsQueueLabelToQueueWeCurrentlyRun {
    // We're running on main thread
    expect(self.message.queueLabel).to.equal(@"com.apple.main-thread");
}


- (void)testInitAssignsFileParameterWithoutCopyFileOption {
    NSMutableString *file = [NSMutableString stringWithString:@"file"];
    self.message = [DDLogMessage test_messageWithFile:file options:(DDLogMessageOptions)0];
    expect(self.message.file).to.equal(@"file");
    [file appendString:@"file"];
    expect(self.message.file).to.equal(@"filefile");
}

- (void)testInitCopyFileParameterWithCopyFileOption {
    NSMutableString *file = [NSMutableString stringWithString:@"file"];
    self.message = [DDLogMessage test_messageWithFile:file options:DDLogMessageCopyFile];
    expect(self.message.file).to.equal(@"file");
    [file appendString:@"file"];
    expect(self.message.file).to.equal(@"file");
}

- (void)testInitAssignFunctionParameterWithoutCopyFunctionOption {
    NSMutableString *function = [NSMutableString stringWithString:@"function"];
    self.message = [DDLogMessage test_messageWithFunction:function options:(DDLogMessageOptions)0];
    expect(self.message.function).to.equal(@"function");
    [function appendString:@"function"];
    expect(self.message.function).to.equal(@"functionfunction");
}

- (void)testInitCopyFunctionParameterWithCopyFunctionOption {
    NSMutableString *function = [NSMutableString stringWithString:@"function"];
    self.message = [DDLogMessage test_messageWithFunction:function options:DDLogMessageCopyFunction];
    expect(self.message.function).to.equal(@"function");
    [function appendString:@"function"];
    expect(self.message.function).to.equal(@"function");
}

- (void)testCopyWithZoneCreatesValidCopy {
    DDLogMessage *copy = [self.message copy];
    expect(self.message.message).to.equal(copy.message);
    expect(self.message.level).to.equal(copy.level);
    expect(self.message.flag).to.equal(copy.flag);
    expect(self.message.context).to.equal(copy.context);
    expect(self.message.file).to.equal(copy.file);
    expect(self.message.fileName).to.equal(copy.fileName);
    expect(self.message.function).to.equal(copy.function);
    expect(self.message.line).to.equal(copy.line);
    expect(self.message.tag).to.equal(copy.tag);
    expect(self.message.options).to.equal(copy.options);
    expect(self.message.timestamp).to.equal(copy.timestamp);
    expect(self.message.threadID).to.equal(copy.threadID);
    expect(self.message.threadName).to.equal(copy.threadName);
    expect(self.message.queueLabel).to.equal(copy.queueLabel);
}

@end

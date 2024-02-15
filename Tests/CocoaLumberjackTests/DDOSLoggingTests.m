// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2024, Deusty, LLC
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

#import <os/log.h>

#import <CocoaLumberjack/DDOSLogger.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDLogMacros.h>

@interface DDTestOSLogLevelMapper: NSObject <DDOSLogLevelMapper>

@property (nonatomic, strong) id<DDOSLogLevelMapper> underlyingMapper;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *collectedLogFlags;

@end

@implementation DDTestOSLogLevelMapper

- (instancetype)initWithUnderlyingMapper:(id<DDOSLogLevelMapper>)underlyingMapper
{
    self = [super init];
    if (self) {
        self.underlyingMapper = underlyingMapper;
        self.collectedLogFlags = [NSMutableArray array];
    }
    return self;
}

- (os_log_type_t)osLogTypeForLogFlag:(DDLogFlag)logFlag {
    [self.collectedLogFlags addObject:@(logFlag)];
    return [self.underlyingMapper osLogTypeForLogFlag:logFlag];
}

@end

@interface DDOSLoggingTests : XCTestCase
@end

@implementation DDOSLoggingTests

- (void)setUp {
    [super setUp];
    [DDLog removeAllLoggers];
}

- (void)tearDown {
    [DDLog removeAllLoggers];
    [super tearDown];
}

- (void)testRegisterLogger {
    if (@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)) {
        __auto_type logger = [DDOSLogger new];
        [DDLog addLogger:logger];
        XCTAssertEqualObjects(logger.loggerName, DDLoggerNameOS);
        XCTAssertEqualObjects(logger, DDLog.allLoggers.firstObject);
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        __auto_type logger = [DDASLLogger new];
        [DDLog addLogger:logger];
        XCTAssertEqualObjects(logger.loggerName, DDLoggerNameASL);
        XCTAssertEqualObjects(logger, DDLog.allLoggers.firstObject);
#pragma clang diagnostic pop
    }
}

- (void)testDDOSLogLevelMapper {
    __auto_type mapper = [[DDTestOSLogLevelMapper alloc] initWithUnderlyingMapper:[[DDOSLogLevelMapperDefault alloc] init]];
    __auto_type logger = [[DDOSLogger alloc] initWithLogLevelMapper:mapper];
    [DDLog addLogger:logger];

    __auto_type ddLogLevel = DDLogLevelVerbose;
    DDLogVerbose(@"VERBOSE");
    DDLogDebug(@"DEBUG");
    DDLogInfo(@"INFO");
    DDLogWarn(@"WARN");
    DDLogError(@"ERROR");

    XCTAssertEqual(mapper.collectedLogFlags.count, 5);
    if (mapper.collectedLogFlags.count < 5) return; // prevent test crashes
    XCTAssertEqual(mapper.collectedLogFlags[0].unsignedIntegerValue, DDLogFlagVerbose);
    XCTAssertEqual(mapper.collectedLogFlags[1].unsignedIntegerValue, DDLogFlagDebug);
    XCTAssertEqual(mapper.collectedLogFlags[2].unsignedIntegerValue, DDLogFlagInfo);
    XCTAssertEqual(mapper.collectedLogFlags[3].unsignedIntegerValue, DDLogFlagWarning);
    XCTAssertEqual(mapper.collectedLogFlags[4].unsignedIntegerValue, DDLogFlagError);
}

- (void)testDDOSLogLevelMapperDefault {
    __auto_type mapper = [[DDOSLogLevelMapperDefault alloc] init];
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagVerbose], OS_LOG_TYPE_DEBUG);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagDebug], OS_LOG_TYPE_DEBUG);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagInfo], OS_LOG_TYPE_INFO);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagWarning], OS_LOG_TYPE_ERROR);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagError], OS_LOG_TYPE_ERROR);
    XCTAssertEqual([mapper osLogTypeForLogFlag:NSUIntegerMax], OS_LOG_TYPE_DEFAULT);
}

#if TARGET_OS_SIMULATOR
- (void)testDDOSLogLevelMapperSimulatorConsoleAppWorkaround {
    __auto_type mapper = [[DDOSLogLevelMapperSimulatorConsoleAppWorkaround alloc] init];
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagVerbose], OS_LOG_TYPE_DEFAULT);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagDebug], OS_LOG_TYPE_DEFAULT);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagInfo], OS_LOG_TYPE_INFO);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagWarning], OS_LOG_TYPE_ERROR);
    XCTAssertEqual([mapper osLogTypeForLogFlag:DDLogFlagError], OS_LOG_TYPE_ERROR);
    XCTAssertEqual([mapper osLogTypeForLogFlag:NSUIntegerMax], OS_LOG_TYPE_DEFAULT);
}
#endif

@end

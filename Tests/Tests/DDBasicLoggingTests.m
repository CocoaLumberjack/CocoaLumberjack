//
//  DDBasicLoggingTests.m
//  CocoaLumberjack Tests
//
//  Created by Bogdan on 09/03/15.
//  Copyright (c) 2015 deusty. All rights reserved.
//

@import XCTest;
#import <CocoaLumberjack.h>

DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface DDBasicLoggingTests : XCTestCase

@end

@implementation DDBasicLoggingTests

+ (void)setUp {
    [super setUp];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testAllBasicLevels {
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
}

@end

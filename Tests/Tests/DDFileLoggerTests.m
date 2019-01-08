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

@interface DDFileLoggerTests : XCTestCase

@end

@implementation DDFileLoggerTests

- (void)testBuffer {
    __auto_type logger = [DDFileLogger new];
    __auto_type wrapped = [logger wrapWithBuffer];
    XCTAssert([wrapped.class isSubclassOfClass:NSProxy.class]);
    __auto_type unwrapped = [wrapped unwrapFromBuffer];
    XCTAssert([unwrapped.class isSubclassOfClass:DDFileLogger.class]);
}

@end

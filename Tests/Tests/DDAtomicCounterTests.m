// Software License Agreement (BSD License)
//
// Copyright (c) 2014-2016, Deusty, LLC
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
#import "DDDispatchQueueLogFormatter.h"
#import <Expecta/Expecta.h>

@interface DDAtomicCounterTests : XCTestCase

@end

@implementation DDAtomicCounterTests

- (void)testSimpleAtomicCounter {
    DDAtomicCounter *atomicCounter = [[DDAtomicCounter alloc] initWithDefaultValue:0];
    expect([atomicCounter value]).to.equal(0);
    expect([atomicCounter increment]).to.equal(1);
    expect([atomicCounter value]).to.equal(1);
    expect([atomicCounter decrement]).to.equal(0);
    expect([atomicCounter value]).to.equal(0);
}

- (void)testMultithreadAtomicCounter {
    DDAtomicCounter *atomicCounter = [[DDAtomicCounter alloc] initWithDefaultValue:0];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Multithread atomic counter"];
    dispatch_queue_global_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block BOOL firstOpDidFinish = NO;
    __block BOOL secondOpDidFinish = NO;
    dispatch_async(globalQueue, ^{
        [atomicCounter increment];
        expect([atomicCounter value]).to.equal(2);
        firstOpDidFinish = YES;
        if (firstOpDidFinish && secondOpDidFinish) {
            [expectation fulfill];
        }
    });
    dispatch_async(globalQueue, ^{
        [atomicCounter increment];
        expect([atomicCounter value]).to.equal(2);
        secondOpDidFinish = YES;
        if (firstOpDidFinish && secondOpDidFinish) {
            [expectation fulfill];
        }
    });
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

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

#import <CocoaLumberjack/DDDispatchQueueLogFormatter.h>

@interface DDAtomicCounterTests : XCTestCase
@end

@implementation DDAtomicCounterTests

- (void)testSimpleAtomicCounter {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type atomicCounter = [[DDAtomicCounter alloc] initWithDefaultValue:0];
#pragma clang diagnostic pop
    XCTAssertEqual([atomicCounter value], 0);
    XCTAssertEqual([atomicCounter increment], 1);
    XCTAssertEqual([atomicCounter value], 1);
    XCTAssertEqual([atomicCounter decrement], 0);
    XCTAssertEqual([atomicCounter value], 0);
}

- (void)testMultithreadAtomicCounter {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type atomicCounter = [[DDAtomicCounter alloc] initWithDefaultValue:0];
#pragma clang diagnostic pop
    __auto_type expectation = [self expectationWithDescription:@"Multithread atomic counter"];
    __auto_type globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    static NSInteger numberOfThreads = 5;
    expectation.expectedFulfillmentCount = numberOfThreads;
    for (NSInteger i = 0; i < numberOfThreads; i++) {
        dispatch_async(globalQueue, ^{
            [atomicCounter increment];
            XCTAssertGreaterThanOrEqual([atomicCounter value], 1);
            [expectation fulfill];
        });
    }

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqual([atomicCounter value], numberOfThreads);
    }];
}

- (void)testMultithreadAtomicCounterWithIncrementAndDecrement {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __auto_type atomicCounter = [[DDAtomicCounter alloc] initWithDefaultValue:0];
#pragma clang diagnostic pop
    __auto_type expectation = [self expectationWithDescription:@"Multithread atomic counter inc and dec"];
    __auto_type globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    static NSInteger numberOfThreads = 5;
    expectation.expectedFulfillmentCount = numberOfThreads * 2;

    for (NSInteger i = 0; i < numberOfThreads; i++) {
        dispatch_async(globalQueue, ^{
            [atomicCounter increment];
            [expectation fulfill];
        });
        dispatch_async(globalQueue, ^{
            [atomicCounter decrement];
            [expectation fulfill];
        });
    }

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqual([atomicCounter value], 0);
    }];
}

@end

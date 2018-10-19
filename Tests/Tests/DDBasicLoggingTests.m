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
//#import <OCMock/OCMock.h>
//#import <Expecta/Expecta.h>

const NSTimeInterval kAsyncExpectationTimeout = 3.0f;

static DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface DDBasicLoggingTests : XCTestCase

@property (nonatomic, strong) NSArray *logs;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, strong) DDAbstractLogger *logger;
@property (nonatomic, assign) NSUInteger noOfMessagesLogged;

@end

@interface DDBasicMockArgument: NSObject
@property (copy, nonatomic, readwrite) void(^block)(id object);
+ (instancetype)alongsideWithBlock:(void(^)(id object))block;
@end

@implementation DDBasicMockArgument
- (instancetype)initWithBlock:(void(^)(id object))block {
    if (self = [super init]) {
        self.block = block;
    }
    return self;
}
+ (instancetype)alongsideWithBlock:(void(^)(id object))block {
    return [[self alloc] initWithBlock:block];
}
- (id)copyWithZone:(NSZone *)zone {
    return [self.class alongsideWithBlock:self.block];
}
@end

@interface DDBasicMockArgumentPosition: NSObject <NSCopying>
@property (copy, nonatomic, readwrite) NSString *selector;
@property (copy, nonatomic, readwrite) NSNumber *position;
- (instancetype)initWithSelector:(NSString *)selector position:(NSNumber *)position;
@end

@implementation DDBasicMockArgumentPosition

- (instancetype)initWithSelector:(NSString *)selector position:(NSNumber *)position {
    if (self = [super init]) {
        self.selector = selector;
        self.position = position;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self.class alloc] initWithSelector:self.selector position:self.position];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@ selector: %@ position: %@", [super debugDescription], self.selector, self.position];
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ selector: %@ position: %@", [super description], self.selector, self.position];
}
@end

@interface DDBasicMock<T>: NSProxy
+ (instancetype)decoratedInstance:(T)object;
- (instancetype)enableStub;
- (instancetype)disableStub;
- (void)addArgument:(DDBasicMockArgument *)argument forSelector:(SEL)selector atIndex:(NSInteger)index;
@end

@interface DDBasicMock ()
@property (strong, nonatomic, readwrite) id object;
@property (assign, nonatomic, readwrite) BOOL stubEnabled;
@property (copy, nonatomic, readwrite) NSDictionary <DDBasicMockArgumentPosition *, DDBasicMockArgument *>*handlers; // extend later to NSArray if needed.
@end

@implementation DDBasicMock
@synthesize handlers = _handlers;
- (instancetype)initWithInstance:(id)object {
    self.object = object;
    self.handlers = @{};
    return self;
}
+ (instancetype)decoratedInstance:(id)object {
    return [[self alloc] initWithInstance:object];
}
- (instancetype)enableStub {
    self.stubEnabled = YES;
    return self;
}
- (instancetype)disableStub {
    self.stubEnabled = NO;
    return self;
}
- (void)addArgument:(DDBasicMockArgument *)argument forSelector:(SEL)selector atIndex:(NSInteger)index {
    NSMutableDictionary *dictionary = [self.handlers mutableCopy];
    DDBasicMockArgumentPosition *thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(selector) position:@(index)];
    dictionary[thePosition] = argument;
    self.handlers = dictionary;
}
- (void)forwardInvocation:(NSInvocation *)invocation {
//    if (self.stubEnabled) {
//        // check also that we have correct invocation.
//        // hm..
//        NSUInteger numberOfArguments = [[invocation methodSignature] numberOfArguments];
//        for (NSUInteger i = 2; i < numberOfArguments; ++i) {
//            id argument = nil;
//            [invocation getArgument:&argument atIndex:i];
//            if ([argument isKindOfClass:[DDBasicMockArgument class]]) {
//                DDBasicMockArgument *theArgument = (DDBasicMockArgument *)argument;
//                DDBasicMockArgumentPosition *thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(invocation.selector) position:@(i)];
//
//                NSMutableDictionary *dictionary = [_handlers mutableCopy];
//                dictionary[thePosition] = [theArgument copy];
//                _handlers = dictionary;
//            }
//        }
//    }
//    else {
    NSUInteger numberOfArguments = [[invocation methodSignature] numberOfArguments];
    for (NSUInteger i = 2; i < numberOfArguments; ++i) {
        id argument = nil;
        [invocation getArgument:&argument atIndex:i];
        DDBasicMockArgumentPosition *thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(invocation.selector) position:@(i)];
        DDBasicMockArgument *theArgument = _handlers[thePosition];
        NSLog(@"%@ here we have: thePosition: %@ and theArgument: %@. All Handlers: %@", self, thePosition, theArgument, _handlers);
        if (theArgument.block) {
            theArgument.block(argument);
        }
    }
    [invocation setTarget:self.object];
    [invocation invoke];
//    }
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.object methodSignatureForSelector:sel];
}
//- (void)doesNotRecognizeSelector:(SEL)aSelector {
//    NSLog(@"%s -> %@", __PRETTY_FUNCTION__, NSStringFromSelector(aSelector));
//    [self.object doesNotRecognizeSelector:aSelector];
//}
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.object respondsToSelector:aSelector];
}
@end

@interface DDBasicMockAbstractLogger: DDAbstractLogger
@property (copy, nonatomic, readwrite) void(^block)(id object);
- (instancetype)configuredWithBlock:(void(^)(id object))block;
@end
@implementation DDBasicMockAbstractLogger
- (void)logMessage:(DDLogMessage *)logMessage {
    if (self.block) {
        self.block(logMessage);
    }
    else {
        [super logMessage:logMessage];
    }
}
- (instancetype)configuredWithBlock:(void (^)(id))block {
    self.block = block;
    return self;
}
@end

@implementation DDBasicLoggingTests

- (void)reactOnMessage:(id)object {
    DDLogMessage *message = (DDLogMessage *)object;
    XCTAssertTrue([self.logs containsObject:message.message]);
    self.noOfMessagesLogged++;
    if (self.noOfMessagesLogged == [self.logs count]) {
        [self.expectation fulfill];
    }
}

- (void)cleanup {
    [DDLog removeAllLoggers];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:self.logger];
    
    ddLogLevel = DDLogLevelVerbose;
    
    self.logs = @[];
    self.expectation = nil;
    self.noOfMessagesLogged = 0;
}

- (void)setUp {
    [super setUp];
    
    if (self.logger == nil) {
        __weak typeof(self) weakSelf = self;
        DDBasicMockAbstractLogger *logger = [[DDBasicMockAbstractLogger new] configuredWithBlock:^(id object) {
            [weakSelf reactOnMessage:object];
        }];
        self.logger = logger;
    }
    
    [self cleanup];
}

- (void)oldSetUp {
    [super setUp];
    
    if (self.logger == nil) {
        DDBasicMock<DDAbstractLogger *> *logger = [DDBasicMock<DDAbstractLogger *> decoratedInstance:[[DDAbstractLogger alloc] init]];

        __weak typeof(self)weakSelf = self;
        DDBasicMockArgument *argument = [DDBasicMockArgument alongsideWithBlock:^(id object) {
            [weakSelf reactOnMessage:object];
        }];
        
        [logger addArgument:argument forSelector:@selector(logMessage:) atIndex:2];

//        [logger enableStub];
        
//        [(DDAbstractLogger *)logger logMessage:];
//        [logger disableStub];
        
        self.logger = (DDAbstractLogger *)logger;
    }

    [self cleanup];
}

- (void)testAll5DefaultLevelsAsync {
    self.expectation = [self expectationWithDescription:@"default log levels"];
    self.logs = @[ @"Error", @"Warn", @"Info", @"Debug", @"Verbose" ];
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
}

- (void)testLoggerLogLevelAsync {
    self.expectation = [self expectationWithDescription:@"logger level"];
    self.logs = @[ @"Error", @"Warn" ];
    
    [DDLog removeLogger:self.logger];
    [DDLog addLogger:self.logger withLevel:DDLogLevelWarning];
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
}

- (void)testX_ddLogLevel_async {
    self.expectation = [self expectationWithDescription:@"ddLogLevel"];
    self.logs = @[ @"Error", @"Warn", @"Info" ];
    
    ddLogLevel = DDLogLevelInfo;
    
    DDLogError  (@"Error");
    DDLogWarn   (@"Warn");
    DDLogInfo   (@"Info");
    DDLogDebug  (@"Debug");
    DDLogVerbose(@"Verbose");
    
    [self waitForExpectationsWithTimeout:kAsyncExpectationTimeout handler:^(NSError *timeoutError) {
        XCTAssertNil(timeoutError);
    }];
    
    ddLogLevel = DDLogLevelVerbose;
}

@end

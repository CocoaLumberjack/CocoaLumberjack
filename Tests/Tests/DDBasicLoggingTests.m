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

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    DDBasicMockArgumentPosition *position = (DDBasicMockArgumentPosition *)object;
    
    return [position.selector isEqualToString:self.selector] && [position.position isEqualToNumber:self.position];
}

- (NSUInteger)hash {
    return [self.selector hash] + [self.position hash];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@ selector: %@ position: %@", [super debugDescription], self.selector, self.position];
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ selector: %@ position: %@", [super description], self.selector, self.position];
}
@end

@interface DDBasicMock<T>: NSObject
+ (instancetype)decoratedInstance:(T)object;
- (instancetype)enableStub;
- (instancetype)disableStub;
- (void)addArgument:(DDBasicMockArgument *)argument forSelector:(SEL)selector atIndex:(NSInteger)index;
@end

@interface DDBasicMock ()
@property (strong, nonatomic, readwrite) id object;
@property (assign, nonatomic, readwrite) BOOL stubEnabled;
@property (copy, nonatomic, readwrite) NSDictionary <DDBasicMockArgumentPosition *, DDBasicMockArgument *>*positionsAndArguments; // extend later to NSArray if needed.
@end

@implementation DDBasicMock
- (instancetype)initWithInstance:(id)object {
    self.object = object;
    self.positionsAndArguments = [NSDictionary new];
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
    NSMutableDictionary *dictionary = [self.positionsAndArguments mutableCopy];
    DDBasicMockArgumentPosition *thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(selector) position:@(index)];
    dictionary[thePosition] = [argument copy];
    __auto_type theArgument = argument;
    NSLog(@"%s %@ here we have: thePosition: %@ and theArgument: %@. All Handlers: %@", __PRETTY_FUNCTION__, self, thePosition, theArgument, _positionsAndArguments);
    self.positionsAndArguments = dictionary;
    NSLog(@"%s %@ here we have: thePosition: %@ and theArgument: %@. All Handlers: %@", __PRETTY_FUNCTION__, self, thePosition, theArgument, _positionsAndArguments);
}
- (void)abc_forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation setTarget:self.object];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    NSUInteger numberOfArguments = [[invocation methodSignature] numberOfArguments];
    BOOL found = NO;
    for (NSUInteger i = 2; i < numberOfArguments; ++i) {
        void *abc = nil;
        [invocation getArgument:&abc atIndex:i];
        id argument = (__bridge id)(abc);
        DDBasicMockArgumentPosition *thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(invocation.selector) position:@(i)];
        DDBasicMockArgument *theArgument = _positionsAndArguments[thePosition];
        NSLog(@"%@ here we have: thePosition: %@ and theArgument: %@. All Handlers: %@", self, thePosition, theArgument, _positionsAndArguments);
        if (theArgument.block) {
            found = YES;
            theArgument.block(argument);
        }
        [invocation setArgument:(__bridge void * _Nonnull)(argument) atIndex:i];
        argument = nil;
    }
    if (!found) {
        [invocation setTarget:self.object];
        [invocation invoke];
    }
    else {
        [invocation setTarget:nil];
        [invocation invoke];
    }
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.object methodSignatureForSelector:sel];
}
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

- (void)_setUp {
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

- (void)setUp {
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

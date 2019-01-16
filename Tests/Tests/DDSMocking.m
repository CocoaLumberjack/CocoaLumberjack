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

#import "DDSMocking.h"

@implementation DDSMocking
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
    
    __auto_type position = (DDBasicMockArgumentPosition *)object;
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
    __auto_type thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(selector)
                                                                           position:@(index)];
    dictionary[thePosition] = [argument copy];
    self.positionsAndArguments = dictionary;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    __auto_type numberOfArguments = [[invocation methodSignature] numberOfArguments];
    BOOL found = NO;
    for (NSUInteger i = 2; i < numberOfArguments; ++i) {
        void *abc = nil;
        [invocation getArgument:&abc atIndex:i];
        id argument = (__bridge id)(abc);
        __auto_type thePosition = [[DDBasicMockArgumentPosition alloc] initWithSelector:NSStringFromSelector(invocation.selector) position:@(i)];
        __auto_type argListener = self.positionsAndArguments[thePosition];

        if (argListener) {
            found = YES;
            argListener.block(argument);
        }
    }
    if (!found) {
        [invocation invokeWithTarget:self.object];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.object methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.object respondsToSelector:aSelector];
}

@end

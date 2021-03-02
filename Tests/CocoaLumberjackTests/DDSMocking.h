// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2021, Deusty, LLC
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

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface DDSMocking: NSObject
@end

NS_ASSUME_NONNULL_END

@interface DDBasicMockArgument: NSObject
@property (copy, nonatomic, readwrite) void(^block)(id object);
+ (instancetype)alongsideWithBlock:(void(^)(id object))block;
@end

@interface DDBasicMockArgumentPosition: NSObject <NSCopying>
@property (copy, nonatomic, readwrite) NSString *selector;
@property (copy, nonatomic, readwrite) NSNumber *position;
- (instancetype)initWithSelector:(NSString *)selector position:(NSNumber *)position;
@end

@interface DDBasicMock<T>: NSProxy
+ (instancetype)decoratedInstance:(T)object;
- (instancetype)enableStub;
- (instancetype)disableStub;
- (void)addArgument:(DDBasicMockArgument *)argument forSelector:(SEL)selector atIndex:(NSInteger)index;
@end

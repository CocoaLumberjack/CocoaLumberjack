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

#import "DDFileLogger+Buffering.h"
#import "DDFileLogger+Internal.h"

static NSUInteger kMaximumBytesCountInBuffer = (1 << 10) * (1 << 10); // 1 MB.
static NSUInteger kDefaultBytesCountInBuffer = (1 << 10);

// MARK: Public Interface
typedef DDFileLogger* LoggerType;
@interface DDBufferedProxy<FileLogger: LoggerType>: NSProxy
+ (instancetype)decoratedInstance:(FileLogger)instance;
@property (assign, nonatomic, readwrite) NSUInteger maximumBytesCountInBuffer;
@end

@interface DDBufferedProxy<FileLogger: LoggerType> () {
    NSOutputStream *_bufferStream;
    NSUInteger _bufferSize;
}
- (instancetype)initWithInstance:(FileLogger)instance;
@property (strong, nonatomic, readwrite) FileLogger instance;
@end

@interface DDBufferedProxy (StreamManipulation)
- (void)flushBuffer;
- (void)dumpBufferToDisk;
- (void)appendToBuffer:(NSData *)data;
- (BOOL)isBufferFull;
@end

@implementation DDBufferedProxy (StreamManipulation)

- (void)flushBuffer {
    // do something.
    [_bufferStream close];
    _bufferStream = nil;
    _bufferSize = 0;
}

- (void)dumpBufferToDisk {
    // do something.
    __auto_type data = (NSData *)[_bufferStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self.instance logData:data];
    [self flushBuffer];
}

- (void)appendToBuffer:(NSData *)data {
    __auto_type length = data.length;
    if (data.length != 0) {
        if (_bufferStream == nil) {
            _bufferStream = [[NSOutputStream alloc] initToMemory];
            [_bufferStream open];
            _bufferSize = 0;
        }
        __auto_type appendedData = (const uint8_t *)calloc(length, sizeof(uint8_t));
        [data getBytes:(void *)appendedData length:length];
        if (appendedData != NULL) {
            [_bufferStream write:appendedData maxLength:length];
        }
        if (appendedData != NULL) {
            free((void *)appendedData);
        }
        _bufferSize += length;
    }
}

- (BOOL)isBufferFull {
    return _bufferSize > self.maximumBytesCountInBuffer;
}

@end

@implementation DDBufferedProxy
@synthesize maximumBytesCountInBuffer = _maximumBytesCountInBuffer;

#pragma mark - Properties
- (void)setMaximumBytesCountInBuffer:(NSUInteger)maximumBytesCountInBuffer {
    _maximumBytesCountInBuffer = MIN(maximumBytesCountInBuffer, kMaximumBytesCountInBuffer);
}

#pragma mark - Initialization
+ (instancetype)decoratedInstance:(__kindof LoggerType)instance {
    return [[self alloc] initWithInstance:instance];
}

- (instancetype)initWithInstance:(__kindof LoggerType)instance {
    self.instance = instance;
    self.maximumBytesCountInBuffer = kDefaultBytesCountInBuffer;
    return self;
}

- (void)dealloc {
    [self dumpBufferToDisk];
    self.instance = nil;
}

#pragma mark - Logging
- (void)logData:(NSData *)data {
    if ([self isBufferFull]) {
        [self dumpBufferToDisk];
    }
    [self appendToBuffer:data];
}

#pragma mark - NSProxy
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.instance methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.instance respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation setTarget:self.instance];
    [invocation invoke];
}

@end

@implementation  DDFileLogger (Buffering)

- (instancetype)wrapWithBuffer {
    if (self.class == DDBufferedProxy.class) {
        return self;
    }
    else {
        // wrap into proxy.
        return (typeof(self))[DDBufferedProxy decoratedInstance:self];
    }
}

- (instancetype)unwrapFromBuffer {
    if (self.class == DDBufferedProxy.class) {
        __auto_type proxy = (DDBufferedProxy *)self;
        return proxy.instance;
    }
    else {
        return self;
    }
}

@end

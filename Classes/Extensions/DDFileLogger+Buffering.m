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

#import <sys/mount.h>

static NSUInteger kDefaultBytesCountInBuffer = (4 << 10);

// Reads attributes from base file system to determine buffer size.
// see statfs in sys/mount.h for descriptions of f_iosize and f_bsize.
static NSUInteger DDGetDefaultBufferByteLengthMax(BOOL max) {
    struct statfs *mntbufp = NULL;
    int count = getmntinfo(&mntbufp, 0);

    for (int i = 0; i < count; i++) {
        const char *name = mntbufp[i].f_mntonname;
        if (strlen(name) == 1 && *name == '/') {
            if (max) {
                return mntbufp[i].f_iosize;
            } else {
                return mntbufp[i].f_bsize;
            }
        }
    }

    return kDefaultBytesCountInBuffer;
}

// MARK: Public Interface
@interface DDBufferedProxy<FileLogger: DDFileLogger *> : NSProxy

+ (instancetype)decoratedInstance:(FileLogger)instance;

@property (assign, nonatomic, readwrite) NSUInteger maximumBytesCountInBuffer;

@end

@interface DDBufferedProxy<FileLogger: DDFileLogger *> () {
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
    [_bufferStream close];
    _bufferStream = nil;
    _bufferSize = 0;
}

- (void)dumpBufferToDisk {
    NSData *data = [_bufferStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self.instance logData:data];
    [self flushBuffer];
}

- (void)appendToBuffer:(NSData *)data {
    NSUInteger length = data.length;
    if (length == 0) {
        return;
    }

    if (_bufferStream == nil) {
        _bufferStream = [[NSOutputStream alloc] initToMemory];
        [_bufferStream open];
        _bufferSize = 0;
    }

    [_bufferStream write:[data bytes] maxLength:length];
    _bufferSize += length;
}

- (BOOL)isBufferFull {
    return _bufferSize > self.maximumBytesCountInBuffer;
}

@end

@implementation DDBufferedProxy

@synthesize maximumBytesCountInBuffer = _maximumBytesCountInBuffer;

#pragma mark - Properties

- (void)setMaximumBytesCountInBuffer:(NSUInteger)maximumBytesCountInBuffer {
    const NSUInteger maxBufferLength = DDGetDefaultBufferByteLengthMax(YES);
    _maximumBytesCountInBuffer = MIN(maximumBytesCountInBuffer, maxBufferLength);
}

#pragma mark - Initialization

+ (instancetype)decoratedInstance:(DDFileLogger *)instance {
    return [[self alloc] initWithInstance:instance];
}

- (instancetype)initWithInstance:(DDFileLogger *)instance {
    self.instance = instance;
    self.maximumBytesCountInBuffer = DDGetDefaultBufferByteLengthMax(NO);
    return self;
}

- (void)dealloc {
    [self dumpBufferToDisk];
    self.instance = nil;
}

#pragma mark - Logging

- (void)logMessage:(DDLogMessage *)logMessage {
    NSData *data = [self.instance lt_dataForMessage:logMessage];

    if ([self isBufferFull]) {
        [self dumpBufferToDisk];
    }

    [self appendToBuffer:data];
}

- (void)flush {
    // This method is public.
    // We need to execute the rolling on our logging thread/queue.

    dispatch_block_t block = ^{
        @autoreleasepool {
            [self dumpBufferToDisk];
            [self.instance flush];
        }
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    if ([self.instance isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self.instance isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_sync(globalLoggingQueue, ^{
            dispatch_sync(self.instance.loggerQueue, block);
        });
    }
}

#pragma mark - Wrapping

- (DDFileLogger *)wrapWithBuffer {
    return (DDFileLogger *)self;
}

- (DDFileLogger *)unwrapFromBuffer {
    return (DDFileLogger *)self.instance;
}

#pragma mark - NSProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.instance methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.instance respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.instance];
}

@end

@implementation DDFileLogger (Buffering)

- (instancetype)wrapWithBuffer {
    return (typeof(self))[DDBufferedProxy decoratedInstance:self];
}

- (instancetype)unwrapFromBuffer {
    return self;
}

@end

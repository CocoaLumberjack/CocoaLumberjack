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

static NSUInteger kDDDefaultBufferSize = 4096; // 4 kB, block f_bsize on iphone7
static NSUInteger kDDMaxBufferSize = 1048576; // ~1 mB, f_iosize on iphone7

// Reads attributes from base file system to determine buffer size.
// see statfs in sys/mount.h for descriptions of f_iosize and f_bsize.
static NSUInteger DDGetDefaultBufferSizeBytesMax(BOOL max) {
    struct statfs *mntbufp = NULL;
    int count = getmntinfo(&mntbufp, 0);

    for (int i = 0; i < count; i++) {
        const char *name = mntbufp[i].f_mntonname;
        if (strlen(name) == 1 && *name == '/') {
            return max ? mntbufp[i].f_iosize : mntbufp[i].f_bsize;
        }
    }

    return max ? kDDMaxBufferSize : kDDDefaultBufferSize;
}

// MARK: Public Interface
@interface DDBufferedProxy<FileLogger: DDFileLogger *> : NSProxy

+ (instancetype)decoratedInstance:(FileLogger)instance;

@property (assign, nonatomic, readwrite) NSUInteger maxBufferSizeBytes;

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
    return _bufferSize > self.maxBufferSizeBytes;
}

@end

@implementation DDBufferedProxy

@synthesize maxBufferSizeBytes = _maxBufferSizeBytes;

#pragma mark - Properties

- (void)setMaxBufferSizeBytes:(NSUInteger)maximumBytesCountInBuffer {
    const NSUInteger maxBufferLength = DDGetDefaultBufferSizeBytesMax(YES);
    _maxBufferSizeBytes = MIN(maximumBytesCountInBuffer, maxBufferLength);
}

#pragma mark - Initialization

+ (instancetype)decoratedInstance:(DDFileLogger *)instance {
    return [[self alloc] initWithInstance:instance];
}

- (instancetype)initWithInstance:(DDFileLogger *)instance {
    self.instance = instance;
    self.maxBufferSizeBytes = DDGetDefaultBufferSizeBytesMax(NO);
    return self;
}

- (void)dealloc {
    [self dumpBufferToDisk];
    self.instance = nil;
}

#pragma mark - Logging

- (void)logMessage:(DDLogMessage *)logMessage {
    NSData *data = [self.instance lt_dataForMessage:logMessage];

    if (_bufferSize >= _maxBufferSizeBytes) {
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

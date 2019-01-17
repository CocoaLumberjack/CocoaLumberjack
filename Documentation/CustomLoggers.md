How to write your own custom loggers.

### Introduction

Loggers allow you to direct log messages wherever you want. For general information about loggers, see the [architecture](Architecture.md) page. The best part is that it's relatively easy to write your own custom loggers.

The `DDLog` header file defines the `DDLogger` protocol. It consists of only 3 mandatory methods:

```objc
@protocol DDLogger <NSObject>

- (void)logMessage:(DDLogMessage *)logMessage;

/**
 * Formatters may optionally be added to any logger.
 *
 * If no formatter is set, the logger simply logs the message as it is given in logMessage,
 * or it may use its own built in formatting style.
 **/
@property (nonatomic, strong) id <DDLogFormatter> logFormatter;

@optional

/**
 * Since logging is asynchronous, adding and removing loggers is also asynchronous.
 * In other words, the loggers are added and removed at appropriate times with regards to log messages.
 *
 * - Loggers will not receive log messages that were executed prior to when they were added.
 * - Loggers will not receive log messages that were executed after they were removed.
 *
 * These methods are executed in the logging thread/queue.
 * This is the same thread/queue that will execute every logMessage: invocation.
 * Loggers may use these methods for thread synchronization or other setup/teardown tasks.
 **/
- (void)didAddLogger;
- (void)willRemoveLogger;

/**
 * Some loggers may buffer IO for optimization purposes.
 * For example, a database logger may only save occasionally as the disk IO is slow.
 * In such loggers, this method should be implemented to flush any pending IO.
 *
 * This allows invocations of DDLog's flushLog method to be propagated to loggers that need it.
 *
 * Note that DDLog's flushLog method is invoked automatically when the application quits,
 * and it may be also invoked manually by the developer prior to application crashes, or other such reasons.
 **/
- (void)flush;

/**
 * Each logger is executed concurrently with respect to the other loggers.
 * Thus, a dedicated dispatch queue is used for each logger.
 * Logger implementations may optionally choose to provide their own dispatch queue.
 **/
@property (nonatomic, DISPATCH_QUEUE_REFERENCE_TYPE, readonly) dispatch_queue_t loggerQueue;

/**
 * If the logger implementation does not choose to provide its own queue,
 * one will automatically be created for it.
 * The created queue will receive its name from this method.
 * This may be helpful for debugging or profiling reasons.
 **/
@property (nonatomic, readonly) NSString *loggerName;

@end
```
<br/>
<br/>
Furthermore, **there is a base logger implementation one can extend** (`DDAbstractLogger`) that will automatically implement 2 of the 3 mandatory methods (`logFormatter` & `setLogFormatter:`). So implementing a logger can be pretty straight-forward.

### Skeleton Implementation

Let's assume we want to write a custom logger. It doesn't take much to write the skeleton code:

MyCustomLogger.h:
```objc
#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface MyCustomLogger : DDAbstractLogger <DDLogger>
{
}
@end
```

MyCustomLogger.m
```objc
#import "MyCustomLogger.h"

@implementation MyCustomLogger

- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *logMsg = logMessage.message;

    if (self->logFormatter)
        logMsg = [self->logFormatter formatLogMessage:logMessage];

    if (logMsg) {
        // Write logMsg to wherever...
    }
}

@end
```

Pretty simple huh?

### Details

The logFormatter is designed to be an optional component for loggers. This is for simplicity. And the separation between loggers and formatters is for reusability. A single formatter can be applied to multiple loggers.

However, you are obviously free to do whatever you want. If it doesn't make sense to support formatters for your custom logger, you don't have to. (This may be the case with database loggers.) And if your custom logger is to use a single pre-defined format, then you can simply do the formatting directly within the logger itself, and forego the formatter. It is completely up to you.

The DDLogMessage object encapsulates the information about a log message. It is also defined in DDLog.h:

```objc
@interface DDLogMessage : NSObject <NSCopying>
{
    // Direct accessors to be used only for performance
    ...
}

@property (readonly, nonatomic) NSString *message;
@property (readonly, nonatomic) DDLogLevel level;
@property (readonly, nonatomic) DDLogFlag flag;
@property (readonly, nonatomic) NSInteger context;
@property (readonly, nonatomic) NSString *file;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSString *function;
@property (readonly, nonatomic) NSUInteger line;
@property (readonly, nonatomic) id tag;
@property (readonly, nonatomic) DDLogMessageOptions options;
@property (readonly, nonatomic) NSDate *timestamp;
@property (readonly, nonatomic) NSString *threadID; // ID as it appears in NSLog calculated from the machThreadID
@property (readonly, nonatomic) NSString *threadName;
@property (readonly, nonatomic) NSString *queueLabel;

```

### Threading

Almost all of the multi-threading issues are solved for you. The following 3 methods are **always** invoked on the same thread/gcd_dispatch_queue.
```objc
- (void)logMessage:(DDLogMessage *)logMessage;

- (void)didAddLogger;
- (void)willRemoveLogger;
```

Using these 3 methods you can setup resources, perform logging, and teardown resources without worrying about multi-threaded complications.

Furthermore, the `DDAbstractLogger` provides thread-safe implementations of `setLogFormatter:` and `logFormatter`. And it does so in such a way that allows you to access the logFormatter variable directly from within your logMessage method! (Performance win!)

However, if your custom logger has custom configuration variables, you may need to make them atomic and/or thread-safe.

How to write your own custom formatters.

# Introduction

**Formatters may optionally be added to any logger.** For example, a formatter which prepends the log level (error, warn, info, etc) to log messages being written to a file. To achieve this you may simply create and add a formatter to a file logger. Using formatters gives you the ability to customize the log message appearance without having to rewrite your log messages (or any component of the logging framework).

**Formatters can also be used to filter log messages.** That is, you can determine that certain log messages be excluded from a particular logger. For example, you could have a verbose console log, but a concise log file by filtering all but errors and warnings going to a file logger. The criteria for filtering is entirely up to you.

And remember that **formatters are applied individually to loggers**. So you can format and/or filter on a per-logger basis.

# Details

It is incredibly simple to create your own custom formatter. The protocol for `DDLogFormatter` is defined in `DDLog.h`, and there is only a single required method:
```objective-c
@protocol DDLogFormatter <NSObject>
@required

/**
 * Formatters may optionally be added to any logger.
 * This allows for increased flexibility in the logging environment.
 * For example, log messages for log files may be formatted differently than log messages for the console.
 *
 * For more information about formatters, see the "Custom Formatters" page:
 * Documentation/CustomFormatters.md
 *
 * The formatter may also optionally filter the log message by returning nil,
 * in which case the logger will not log the message.
 **/
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage;

@optional
// ...
@end
```

It's pretty straight-forward. The single method takes, as a parameter, an instance of `DDLogMessage` which contains all the information related to the log message including:

-  `message` - original log message
-  `file` - full path to the file the log message came from
-  `fileName` - name of the file the log message came from (without extension)
-  `function` - method the log message came from
-  `line` - line number in file where the log message came from
-  `timestamp` - when the log message was executed
-  `level` - log level of message (bitmask of flags, e.g. 0111)
-  `flag` - log flag of message (individual flag that allowed log message to fire, e.g. 0010)
-  `threadID` - which thread issued the log message
-  `queueLabel` - name of gcd queue (if applicable)

Let's write a simple formatter that automatically simply prepends the log level before every log message.  

The idea is to get log messages like this:

```objective-c
DDLogError(@"Paper Jam!");       // E | Paper Jam!
DDLogWarn(@"Low toner.");        // W | Low toner.
DDLogInfo(@"Doc printed.");      // I | Doc printed.
DDLogDebug(@"Debugging");        // D | Debugging
DDLogVerbose(@"Init doc_parse"); // V | Init doc_parse.
```

MyCustomFormatter.h
```objective-c
#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface MyCustomFormatter : NSObject <DDLogFormatter>

@end
```

MyCustomFormatter.m
```objective-c
#import "MyCustomFormatter.h"

@implementation MyCustomFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError    : logLevel = @"E"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }
    
    return [NSString stringWithFormat:@"%@ | %@\n", logLevel, logMessage->_message];
}

@end
```

Now, just add the custom formatter to your logger:
```
[DDTTYLogger sharedInstance].logFormatter = [[MyCustomFormatter alloc] init];
```
# Thread-safety (simple)

Let's update our example formatter to also include the timestamp. To do this we'll use `NSDateFormatter`. But... `NSDateFormatter` is NOT thread-safe (unless you're targeting iOS 7+, or OSX 10.9+ with modern behavior on 64-bit architecture, see [NSDateFormatter](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSDateFormatter_Class/])). Does this pose any problems for us?

Log formatters are applied individually to loggers. If you instantiate a log formatter instance, **and apply it to a single logger**, then you don't have to worry about thread-safety. All log messages are sent to the logger (and thus to its log formatter) via the serial dispatch queue of the logger. Thus, in this scenario, the formatLogMessage method is guaranteed to run on only a single thread at a time.

It is very often the case that developers write custom formatters specifically for a particular logger. Thus it is often the case that thread-safety won't be a concern. However, defensive programming is encouraged. There are a few simple hooks that one can use to ensure their thread-unsafe log formatter isn't used inappropriately.

```objective-c
@protocol DDLogFormatter <NSObject>
@required

/**
 * Formatters may optionally be added to any logger.
 * This allows for increased flexibility in the logging environment.
 * For example, log messages for log files may be formatted differently than log messages for the console.
 *
 * For more information about formatters, see the "Custom Formatters" page:
 * Documentation/CustomFormatters.md
 *
 * The formatter may also optionally filter the log message by returning nil,
 * in which case the logger will not log the message.
 **/
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage;

@optional

/**
 * A single formatter instance can be added to multiple loggers.
 * These methods provides hooks to notify the formatter of when it's added/removed.
 *
 * This is primarily for thread-safety.
 * If a formatter is explicitly not thread-safe, it may wish to throw an exception if added to multiple loggers.
 * Or if a formatter has potentially thread-unsafe code (e.g. NSDateFormatter),
 * it could possibly use these hooks to switch to thread-safe versions of the code.
 **/
- (void)didAddToLogger:(id <DDLogger>)logger;
- (void)willRemoveFromLogger:(id <DDLogger>)logger;

@end
```

Using these hooks, we can add a very simple measure to ensure we don't accidentally shoot ourself in the foot in the future.

This time the idea is to get log messages like this:

```objective-c
DDLogError(@"Paper Jam!");       // E 2010/05/20 15:33:18:621 | Paper Jam!
DDLogWarn(@"Low toner.");        // W 2010/05/20 15:33:18:621 | Low toner.
DDLogInfo(@"Doc printed.");      // I 2010/05/20 15:33:18:621 | Doc printed.
DDLogDebug(@"Debugging");        // D 2010/05/20 15:33:18:621 | Debugging
DDLogVerbose(@"Init doc_parse"); // V 2010/05/20 15:33:18:621 | Init doc_parse.
```

MyCustomFormatter.h
```objective-c
#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface MyCustomFormatter : NSObject <DDLogFormatter> {
    int loggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}
@end
```

MyCustomFormatter.m
```objective-c
#import "MyCustomFormatter.h"

@implementation MyCustomFormatter

- (id)init {
    if((self = [super init])) {
        threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [threadUnsafeDateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError    : logLevel = @"E"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }

    NSString *dateAndTime = [threadUnsafeDateFormatter stringFromDate:(logMessage->_timestamp)];
    NSString *logMsg = logMessage->_message;
    
    return [NSString stringWithFormat:@"%@ %@ | %@\n", logLevel, dateAndTime, logMsg];
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    loggerCount++;
    NSAssert(loggerCount <= 1, @"This logger isn't thread-safe");
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    loggerCount--;
}

@end
```

# Thread-safety (advanced)

If a log formatter is applied to only a single logger, then thread-safety isn't generally a concern. However, it is perfectly legal to apply a single log formatter instance to multiple loggers. In this case, thread-safety is a concern as the log formatter may be running concurrently on multiple threads. That is, multiple loggers (e.g. console logger & file logger) are run concurrently within Lumberjack, and thus a single log formatter instance attached to both would run concurrently as well.

However, it's typically not that difficult to support multi-threading. The most common case involves NSDateFormatter. These are not thread-safe, but there is a well established work-around by storing instances of NSDateFormatter in the thread dictionary. For example:

```objective-c
NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];

if (dateFormatter == nil) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormatString];
    
    [threadDictionary setObject:dateFormatter forKey:key];
}
```

But what about the cost? There is fairly small overhead to extract the dateFormatter from the thread dictionary. And there may also be a small overhead to create the dateFormatter instance's on multiple threads within the GCD thread-pool. To mitigate these costs in the common case (single-thread case), while still maintaining support for the multi-thread case, a hybrid approach may be used:

MyCustomFormatter.h
```objective-c
#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface MyCustomFormatter : NSObject <DDLogFormatter> {
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}
@end
```

MyCustomFormatter.m
```objective-c
#import "MyCustomFormatter.h"
#import <libkern/OSAtomic.h>

@implementation MyCustomFormatter

- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setDateFormat:dateFormatString];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:dateFormatString];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError    : logLevel = @"E"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }

    NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
    NSString *logMsg = logMessage->_message;
    
    return [NSString stringWithFormat:@"%@ %@ | %@\n", logLevel, dateAndTime, logMsg];
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
```

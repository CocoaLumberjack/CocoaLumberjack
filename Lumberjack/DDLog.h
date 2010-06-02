#import <Foundation/Foundation.h>

/**
 * Welcome to Cocoa Lumberjack!
 * 
 * The Google Code page has a wealth of documentation if you have any questions.
 * http://code.google.com/p/cocoalumberjack/
 * 
 * If you're new to the project you may wish to read the "Getting Started" page.
 * http://code.google.com/p/cocoalumberjack/wiki/GettingStarted
 * 
 * Otherwise, here is a quick refresher.
 * There are three steps to using the macros:
 * 
 * Step 1:
 * Import the header in your implementation file:
 * 
 * #import "DDLog.h"
 * 
 * Step 2:
 * Define your logging level in your implementation file:
 * 
 * // Debug levels: off, error, warn, info, verbose
 * static const int ddLogLevel = LOG_LEVEL_VERBOSE;
 * 
 * Step 3:
 * Replace your NSLog statements with DDLog statements according to the severity of the message.
 * 
 * NSLog(@"Fatal error, no dohickey found!"); -> DDLogError(@"Fatal error, no dohickey found!");
 * 
 * DDLog works exactly the same as NSLog.
 * This means you can pass it multiple variables just like NSLog.
**/


// Can we use Grand Central Dispatch?

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060 // Mac OS X 10.6
  #define GCD_AVAILABLE 1
#elif __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000 // iPhone 4.0
  #define GCD_AVAILABLE 1
#else
  #define GCD_AVAILABLE 0
#endif

@class DDLogMessage;

@protocol DDLogger;
@protocol DDLogFormatter;

/**
 * Define our big multiline macros so all the other macros will be easy to read.
**/

#define LOG_MACRO(isSynchronous, lvl, flg, fnct, frmt, ...) \
  [DDLog log:isSynchronous                                  \
       level:lvl                                            \
        flag:flg                                            \
        file:__FILE__                                       \
    function:fnct                                           \
        line:__LINE__                                       \
      format:(frmt), ##__VA_ARGS__]

#define  SYNC_LOG_OBJC_MACRO(lvl, flg, frmt, ...) LOG_MACRO(YES, lvl, flg, sel_getName(_cmd), frmt, ##__VA_ARGS__)
#define ASYNC_LOG_OBJC_MACRO(lvl, flg, frmt, ...) LOG_MACRO( NO, lvl, flg, sel_getName(_cmd), frmt, ##__VA_ARGS__)

#define  SYNC_LOG_C_MACRO(lvl, flg, frmt, ...)    LOG_MACRO(YES, lvl, flg, __FUNCTION__, frmt, ##__VA_ARGS__)
#define ASYNC_LOG_C_MACRO(lvl, flg, frmt, ...)    LOG_MACRO( NO, lvl, flg, __FUNCTION__, frmt, ##__VA_ARGS__)

#define LOG_MAYBE(isSynchronous, lvl, flg, fnct, frmt, ...) \
  do { if(lvl & flg) LOG_MACRO(isSynchronous, lvl, flg, fnct, frmt, ##__VA_ARGS__); } while(0)

#define  SYNC_LOG_OBJC_MAYBE(lvl, flg, frmt, ...) LOG_MAYBE(YES, lvl, flg, sel_getName(_cmd), frmt, ##__VA_ARGS__)
#define ASYNC_LOG_OBJC_MAYBE(lvl, flg, frmt, ...) LOG_MAYBE( NO, lvl, flg, sel_getName(_cmd), frmt, ##__VA_ARGS__)

#define  SYNC_LOG_C_MAYBE(lvl, flg, frmt, ...)    LOG_MAYBE(YES, lvl, flg, __FUNCTION__, frmt, ##__VA_ARGS__)
#define ASYNC_LOG_C_MAYBE(lvl, flg, frmt, ...)    LOG_MAYBE( NO, lvl, flg, __FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * Define our standard log levels.
 * 
 * We default to only 4 levels because it makes it easier for beginners
 * to make the transition to a logging framework.
 * 
 * More advanced users may choose to completely customize the levels (and level names) to suite their needs.
 * For more information on this see the "Custom Log Levels" page:
 * http://code.google.com/p/cocoalumberjack/wiki/CustomLogLevels
 * 
 * Advanced users may also notice that we're using a bitmask.
 * This is to allow for custom fine grained logging:
 * http://code.google.com/p/cocoalumberjack/wiki/FineGrainedLogging
**/

#define LOG_FLAG_ERROR    (1 << 0)  // 0...0001
#define LOG_FLAG_WARN     (1 << 1)  // 0...0010
#define LOG_FLAG_INFO     (1 << 2)  // 0...0100
#define LOG_FLAG_VERBOSE  (1 << 3)  // 0...1000

#define LOG_LEVEL_OFF     0
#define LOG_LEVEL_ERROR   (LOG_FLAG_ERROR)                                                    // 0...0001
#define LOG_LEVEL_WARN    (LOG_FLAG_ERROR | LOG_FLAG_WARN)                                    // 0...0011
#define LOG_LEVEL_INFO    (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO)                    // 0...0111
#define LOG_LEVEL_VERBOSE (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO | LOG_FLAG_VERBOSE) // 0...1111

#define LOG_ERROR   (ddLogLevel & LOG_FLAG_ERROR)
#define LOG_WARN    (ddLogLevel & LOG_FLAG_WARN)
#define LOG_INFO    (ddLogLevel & LOG_FLAG_INFO)
#define LOG_VERBOSE (ddLogLevel & LOG_FLAG_VERBOSE)

#define DDLogError(frmt, ...)     SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_ERROR,   frmt, ##__VA_ARGS__)
#define DDLogWarn(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_WARN,    frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_INFO,    frmt, ##__VA_ARGS__)
#define DDLogVerbose(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_VERBOSE, frmt, ##__VA_ARGS__)

#define DDLogCError(frmt, ...)    SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_ERROR,   frmt, ##__VA_ARGS__)
#define DDLogCWarn(frmt, ...)    ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_WARN,    frmt, ##__VA_ARGS__)
#define DDLogCInfo(frmt, ...)    ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_INFO,    frmt, ##__VA_ARGS__)
#define DDLogCVerbose(frmt, ...) ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_VERBOSE, frmt, ##__VA_ARGS__)

/**
 * The THIS_FILE macro gives you an NSString of the file name.
 * For simplicity and clarity, the file name does not include the full path or file extension.
 * 
 * For example: DDLogWarn(@"%@: Unable to find thingy", THIS_FILE) -> @"MyViewController: Unable to find thingy"
**/

NSString *ExtractFileNameWithoutExtension(const char *filePath, BOOL copy);

#define THIS_FILE (ExtractFileNameWithoutExtension(__FILE__, NO))

/**
 * The THIS_METHOD macro gives you the name of the current objective-c method.
 * 
 * For example: DDLogWarn(@"%@ - Requires non-nil strings") -> @"setMake:model: requires non-nil strings"
 * 
 * Note: This does NOT work in straight C functions (non objective-c).
 * Instead you should use the predefined __FUNCTION__ macro.
**/

#define THIS_METHOD NSStringFromSelector(_cmd)


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DDLog : NSObject

#if GCD_AVAILABLE

/**
 * Provides access to the underlying logging queue.
 * This may be helpful to Logger classes for things like thread synchronization.
**/

+ (dispatch_queue_t)loggingQueue;

#else

/**
 * Provides access to the underlying logging thread.
 * This may be helpful to Logger classes for things like thread synchronization.
**/

+ (NSThread *)loggingThread;

#endif

/**
 * Logging Primitive.
 * 
 * This method is used by the macros above.
 * It is suggested you stick with the macros as they're easier to use.
**/

+ (void)log:(BOOL)synchronous
      level:(int)level
       flag:(int)flag
       file:(const char *)file
   function:(const char *)function
       line:(int)line
     format:(NSString *)format, ...;

/**
 * Since logging can be asynchronous, there may be times when you want to flush the logs.
 * The framework invokes this automatically when the application quits.
**/

+ (void)flushLog;

/** 
 * Loggers
 * 
 * If you want your log statements to go somewhere,
 * you should create and add a logger.
**/

+ (void)addLogger:(id <DDLogger>)logger;
+ (void)removeLogger:(id <DDLogger>)logger;

+ (void)removeAllLoggers;

/**
 * Registered Dynamic Logging
 * 
 * These methods allow you to obtain a list of classes that are using registered dynamic logging,
 * and also provides methods to get and set their log level during run time.
**/

+ (NSArray *)registeredClasses;
+ (NSArray *)registeredClassNames;

+ (int)logLevelForClass:(Class)aClass;
+ (int)logLevelForClassWithName:(NSString *)aClassName;

+ (void)setLogLevel:(int)logLevel forClass:(Class)aClass;
+ (void)setLogLevel:(int)logLevel forClassWithName:(NSString *)aClassName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol DDLogger <NSObject>
@required

- (void)logMessage:(DDLogMessage *)logMessage;

/**
 * Formatters may optionally be added to any logger.
 * If no formatter is set, the logger simply logs the message as it is given in logMessage.
 * Or it may use its own built in formatting style.
**/
- (id <DDLogFormatter>)logFormatter;
- (void)setLogFormatter:(id <DDLogFormatter>)formatter;

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

#if GCD_AVAILABLE

/**
 * When Grand Central Dispatch is available
 * each logger is executed concurrently with respect to the other loggers.
 * Thus, a dedicated dispatch queue is created for each logger.
 * The dedicated dispatch queue will receive its name from this method.
 * This may be helpful for debugging or profiling reasons.
**/

- (NSString *)loggerName;

#endif

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol DDLogFormatter <NSObject>
@required

/**
 * Formatters may optionally be added to any logger.
 * This allows for increased flexibility in the logging environment.
 * For example, log messages for log files may be formatted differently than log messages for the console.
 * 
 * The formatter may also optionally filter the log message by returning nil.
**/

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol DDRegisteredDynamicLogging

/**
 * Implement these methods to allow a file's log level to be managed from a central location.
 * 
 * This is useful if you'd like to be able to change log levels for various parts
 * of your code from within the running application.
 * 
 * Imagine pulling up the settings for your application,
 * and being able to configure the logging level on a per file basis.
 * 
 * The implementation can be very straight-forward:
 * 
 * + (int)ddLogLevel
 * {
 *     return ddLogLevel;
 * }
 *  
 * + (void)ddSetLogLevel:(int)logLevel
 * {
 *     ddLogLevel = logLevel;
 * }
**/

+ (int)ddLogLevel;
+ (void)ddSetLogLevel:(int)logLevel;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The DDLogMessage class encapsulates information about the log message.
 * If you write custom loggers or formatters, you will be dealing with objects of this class.
**/

@interface DDLogMessage : NSObject
{

// The public variables below can be accessed directly (for speed).
// For example: logMessage->logLevel
	
@public
	int logLevel;
	int logFlag;
	NSString *logMsg;
	NSDate *timestamp;
	const char *file;
	const char *function;
	int lineNumber;
	mach_port_t machThreadID;

// The private variables below are only calculated if needed.
// You should use the public methods to access this information.
	
@private
	NSString *threadID;
	NSString *fileName;
	NSString *methodName;
}

// The initializer is somewhat reserved for internal use.
// However, if you find need to manually create logMessage objects,
// there is one thing you should be aware of.
// The initializer expects the file and function parameters to be string literals.
// That is, it expects the given strings to exist for the duration of the object's lifetime,
// and it expects the given strings to be immutable.
// In other words, it does not copy these strings, it simply points to them.

- (id)initWithLogMsg:(NSString *)logMsg
               level:(int)logLevel
                flag:(int)logFlag
                file:(const char *)file
            function:(const char *)function
                line:(int)line;

/**
 * Returns the threadID as it appears in NSLog.
 * That is, it is a hexadecimal value which is calculated from the machThreadID.
**/
- (NSString *)threadID;

/**
 * Convenience method to get just the file name, as the file variable is generally the full file path.
 * This method does not include the file extension, which is generally not needed for logging purposes.
**/
- (NSString *)fileName;

/**
 * Returns the function variable in NSString form.
**/
- (NSString *)methodName;

@end

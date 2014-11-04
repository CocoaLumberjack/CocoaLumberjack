/**
 * In order to provide fast and flexible logging, this project uses Cocoa Lumberjack.
 * 
 * The Google Code page has a wealth of documentation if you have any questions.
 * https://github.com/CocoaLumberjack/CocoaLumberjack
 * 
 * Here's what you need to know concerning how logging is setup for CocoaHTTPServer:
 * 
 * There are 4 log levels:
 * - Error
 * - Warning
 * - Info
 * - Verbose
 * 
 * In addition to this, there is a Trace flag that can be enabled.
 * When tracing is enabled, it spits out the methods that are being called.
 * 
 * Please note that tracing is separate from the log levels.
 * For example, one could set the log level to warning, and enable tracing.
 * 
 * All logging is asynchronous, except errors.
 * To use logging within your own custom files, follow the steps below.
 * 
 * Step 1:
 * Import this header in your implementation file:
 * 
 * #import "HTTPLogging.h"
 * 
 * Step 2:
 * Define your logging level in your implementation file:
 * 
 * // Log levels: off, error, warn, info, verbose
 * static const int httpLogLevel = HTTP_DDLogLevelVerbose;
 * 
 * If you wish to enable tracing, you could do something like this:
 * 
 * // Debug levels: off, error, warn, info, verbose
 * static const int httpLogLevel = HTTP_DDLogLevelInfo | HTTP_LOG_FLAG_TRACE;
 * 
 * Step 3:
 * Replace your NSLog statements with HTTPLog statements according to the severity of the message.
 * 
 * NSLog(@"Fatal error, no dohickey found!"); -> HTTPLogError(@"Fatal error, no dohickey found!");
 * 
 * HTTPLog works exactly the same as NSLog.
 * This means you can pass it multiple variables just like NSLog.
**/

#import <CocoaLumberjack/CocoaLumberjack.h>

// Define logging context for every log message coming from the HTTP server.
// The logging context can be extracted from the DDLogMessage from within the logging framework,
// which gives loggers, formatters, and filters the ability to optionally process them differently.

#define HTTP_LOG_CONTEXT 80

// Configure log levels.

#define HTTP_DDLogFlagError   (1 << 0) // 0...00001
#define HTTP_DDLogFlagWarning (1 << 1) // 0...00010
#define HTTP_DDLogFlagInfo    (1 << 2) // 0...00100
#define HTTP_DDLogFlagVerbose (1 << 3) // 0...01000

#define HTTP_DDLogLevelOff     0                                                // 0...00000
#define HTTP_DDLogLevelError   (HTTP_DDLogLevelOff     | HTTP_DDLogFlagError)   // 0...00001
#define HTTP_DDLogLevelWarning (HTTP_DDLogLevelError   | HTTP_DDLogFlagWarning) // 0...00011
#define HTTP_DDLogLevelInfo    (HTTP_DDLogLevelWarning | HTTP_DDLogFlagInfo)    // 0...00111
#define HTTP_DDLogLevelVerbose (HTTP_DDLogLevelInfo    | HTTP_DDLogFlagVerbose) // 0...01111

// Setup fine grained logging.
// The first 4 bits are being used by the standard log levels (0 - 3)
// 
// We're going to add tracing, but NOT as a log level.
// Tracing can be turned on and off independently of log level.

#define HTTP_LOG_FLAG_TRACE   (1 << 4) // 0...10000

// Configure asynchronous logging.
// We follow the default configuration,
// but we reserve a special macro to easily disable asynchronous logging for debugging purposes.

#define HTTP_LOG_ASYNC_ENABLED   YES

// Define logging primitives.
#define HTTPLogError(frmt, ...)    LOG_MAYBE(NO,                        httpLogLevel, HTTP_DDLogFlagError,   \
                                                  HTTP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define HTTPLogWarn(frmt, ...)     LOG_MAYBE(HTTP_LOG_ASYNC_ENABLED,    httpLogLevel, HTTP_DDLogFlagWarning, \
                                                  HTTP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define HTTPLogInfo(frmt, ...)     LOG_MAYBE(HTTP_LOG_ASYNC_ENABLED,    httpLogLevel, HTTP_DDLogFlagInfo,    \
                                                  HTTP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define HTTPLogVerbose(frmt, ...)  LOG_MAYBE(HTTP_LOG_ASYNC_ENABLED, httpLogLevel, HTTP_DDLogFlagVerbose,    \
                                                  HTTP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define HTTPLogTrace()             LOG_MAYBE(HTTP_LOG_ASYNC_ENABLED, nil, __PRETTY_FUNCTION__,   httpLogLevel, HTTP_LOG_FLAG_TRACE,    \
                                                  HTTP_LOG_CONTEXT, @"%@[%p]: %@", THIS_FILE, self, THIS_METHOD)

#define HTTPLogTrace2(frmt, ...)   LOG_MAYBE(HTTP_LOG_ASYNC_ENABLED,   httpLogLevel, HTTP_LOG_FLAG_TRACE,    \
                                                  HTTP_LOG_CONTEXT, frmt, ##__VA_ARGS__)


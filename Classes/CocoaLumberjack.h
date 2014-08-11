
/**
 * Welcome to CocoaLumberjack!
 *
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/CocoaLumberjack/CocoaLumberjack
 *
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/CocoaLumberjack/CocoaLumberjack/wiki/GettingStarted
 *
 * Otherwise, here is a quick refresher.
 * There are three steps to using the macros:
 *
 * Step 1:
 * Import the header in your implementation or prefix file:
 *
 * #import <CocoaLumberjack/CocoaLumberjack.h>
 *
 * Step 2:
 * Define your logging level in your implementation file:
 *
 * // Log levels: off, error, warn, info, verbose
 * static const int ddLogLevel = LOG_LEVEL_VERBOSE;
 *
 * Step 2 [3rd party frameworks]:
 *
 * Define your LOG_LEVEL_DEF to a different variable/function than ddLogLevel:
 *
 * // #undef LOG_LEVEL_DEF // Undefine first only if needed
 * #define LOG_LEVEL_DEF myLibLogLevel
 *
 * Define your logging level in your implementation file:
 *
 * // Log levels: off, error, warn, info, verbose
 * static const int myLibLogLevel = LOG_LEVEL_VERBOSE;
 *
 * Step 3:
 * Replace your NSLog statements with DDLog statements according to the severity of the message.
 *
 * NSLog(@"Fatal error, no dohickey found!"); -> DDLogError(@"Fatal error, no dohickey found!");
 *
 * DDLog works exactly the same as NSLog.
 * This means you can pass it multiple variables just like NSLog.
 **/

#import "DDLog.h"
#import "DDLogMacros.h"
#import "DDAssertMacros.h"

// Loggers
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "DDFileLogger.h"

#import <Foundation/Foundation.h>

#import "DDLog.h"

/**
 * Welcome to Cocoa Lumberjack!
 * 
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 * 
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/GettingStarted
 * 
 * 
 * This class provides a logger for Terminal output or Xcode console output,
 * depending on where you are running your code.
 * 
 * As described in the "Getting Started" page,
 * the traditional NSLog() function directs it's output to two places:
 * 
 * - Apple System Log (so it shows up in Console.app)
 * - StdErr (if stderr is a TTY, so log statements show up in Xcode console)
 * 
 * To duplicate NSLog() functionality you can simply add this logger and an asl logger.
 * However, if you instead choose to use file logging (for faster performance),
 * you may choose to use only a file logger and a tty logger.
**/

@interface DDTTYLogger : DDAbstractLogger <DDLogger>
{
	NSCalendar *calendar;
	NSUInteger calendarUnitFlags;
	
	NSString *appName;
	char *app;
	size_t appLen;
	
	NSString *processID;
	char *pid;
	size_t pidLen;
	
	BOOL colorsEnabled;
	NSMutableArray *colorProfiles;
}

+ (DDTTYLogger *)sharedInstance;

/**
 * Want to use different colors for different log levels?
 * Enable this property.
 * 
 * If you run the application via the Terminal (not Xcode),
 * the logger will map colors to xterm-256color or xterm-color (if available).
 * 
 * Xcode does NOT natively support colors in the Xcode debugging console.
 * You'll need to install the XcodeColors plugin to see colors in the Xcode console.
 * https://github.com/robbiehanson/XcodeColors
 * 
 * The default value if NO.
**/
@property (readwrite, assign) BOOL colorsEnabled;

/**
 * The default color set (foregroundColor, backgroundColor) is:
 * 
 * - LOG_FLAG_ERROR = (red, nil)
 * - LOG_FLAG_WARN  = (orange, nil)
 * 
 * You can customize the colors however you see fit.
 * There are a few things you may need to be aware of:
 * 
 * You are passing a flag, NOT a level.
 * 
 * GOOD : [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:LOG_FLAG_INFO];  // <- Good :)
 *  BAD : [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:LOG_LEVEL_INFO]; // <- BAD! :(
 * 
 * LOG_FLAG_INFO  = 0...00100
 * LOG_LEVEL_INFO = 0...00111 <- Would match LOG_FLAG_INFO and LOG_FLAG_WARN and LOG_FLAG_ERROR
 * 
 * If you run the application within Xcode, then the XcodeColors plugin is required.
 * 
 * If you run the application from a shell, then DDTTYLogger will automatically try to map the given color to
 * the closest available color. (xterm-256color or xterm-color which have 256 and 16 supported colors respectively.)
 * 
 * This method invokes setForegroundColor:backgroundColor:forFlag:context:, and passes the default context (0).
**/
#if TARGET_OS_IPHONE
- (void)setForegroundColor:(UIColor *)txtColor backgroundColor:(UIColor *)bgColor forFlag:(int)mask;
#else
- (void)setForegroundColor:(NSColor *)txtColor backgroundColor:(NSColor *)bgColor forFlag:(int)mask;
#endif

/**
 * Allows you to customize the color for a particular flag, within a particular logging context.
 * 
 * A logging context may identify log messages coming from a 3rd party framework.
 * Logging context's are explained in further detail here:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomContext
**/
#if TARGET_OS_IPHONE
- (void)setForegroundColor:(UIColor *)txtColor backgroundColor:(UIColor *)bgColor forFlag:(int)mask context:(int)ctxt;
#else
- (void)setForegroundColor:(NSColor *)txtColor backgroundColor:(NSColor *)bgColor forFlag:(int)mask context:(int)ctxt;
#endif

/**
 * Clears the color profiles for a particular flag.
 * 
 * This method invokes clearColorsForFlag:context:, and passes the default context (0).
**/
- (void)clearColorsForFlag:(int)mask;

/**
 * Clears the color profiles for a particular flag, within a particular logging context.
**/
- (void)clearColorsForFlag:(int)mask context:(int)context;

/**
 * Clears all color profiles.
**/
- (void)clearColorsForAllFlags;


// Inherited from DDAbstractLogger

// - (id <DDLogFormatter>)logFormatter;
// - (void)setLogFormatter:(id <DDLogFormatter>)formatter;

@end

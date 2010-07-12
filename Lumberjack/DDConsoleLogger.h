#import <Foundation/Foundation.h>
#import <unistd.h>
#import <asl.h>

#import "DDLog.h"

/**
 * The Console Logger enables Lumberjack to function as a drop-in replacement for NSLog.
 * Log statements will show up in Console.app, as well as in Xcode's console.
 * The log statements will have the same look as an equivalent NSLog statements.
 * 
 * All that is needed is to add console logger to the list of active loggers:
 * 
 * [DDLog addLogger:[DDConsoleLogger sharedInstance]];
 * 
 * For more information, see the "Getting Started" page:
 * http://code.google.com/p/cocoalumberjack/wiki/GettingStarted
**/

@interface DDConsoleLogger : NSObject <DDLogger>
{
	aslclient client;
	
	BOOL outputToASL;
	BOOL outputToStdErr;
	BOOL isRunningInXcode;
	
	NSDateFormatter *dateFormatter;
	
	char *app; // Not null terminated
	char *pid; // Not null terminated
	
	int appLen;
	int pidLen;
	
	id <DDLogFormatter> formatter;
}

+ (DDConsoleLogger *)sharedInstance;

/**
 * The console logger (just like NSLog) sends output to:
 * 
 * - The apple system log (ASL) - so it shows up in Console.app
 * - The STDERR file - so it shows up in Xcode's console when running via Xcode.
 * 
 * You may optionally disable either of these output paths.
 * For example, you may wish to disable output to ASL if your application has its own log file.
 * However, for easy debugging, you may wish to keep stderr output so logging shows up in Xcode's console.
**/

- (void)outputToASL:(BOOL)flag;
- (void)outputToStdErr:(BOOL)flag;

@end

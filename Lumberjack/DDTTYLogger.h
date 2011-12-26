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

DDLOG_CLASS_EXPORT
@interface DDTTYLogger : DDAbstractLogger <DDLogger>
{
@private

	BOOL isaTTY;
	
	NSDateFormatter *dateFormatter;
	
	char *app; // Not null terminated
	char *pid; // Not null terminated
	
	size_t appLen;
	size_t pidLen;
}

+ (DDTTYLogger *)sharedInstance;

// Inherited from DDAbstractLogger

// - (id <DDLogFormatter>)logFormatter;
// - (void)setLogFormatter:(id <DDLogFormatter>)formatter;

@end

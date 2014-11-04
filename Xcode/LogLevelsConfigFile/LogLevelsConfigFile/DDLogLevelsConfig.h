/**
 * Welcome to Cocoa Lumberjack!
 * 
 * The Google Code page has a wealth of documentation if you have any questions.
 * http://code.google.com/p/cocoalumberjack/
 * 
 * If you're new to the project you may wish to read the "Getting Started" page.
 * http://code.google.com/p/cocoalumberjack/wiki/GettingStarted
 * 
 * 
 * This class provides a way to set the log levels of the various files
 * within your application from a configuration file.
 * 
 * This sometimes comes in handy when you are collaborating on a large project with a number of developers.
 * Each developer is often working on different parts of the application,
 * and they are naturally increasing the verbosity of the areas of the app they are working on.
 * It's easy to forget to decrease the verbosity prior to checking in code,
 * but likely you don't care about all their debug statements.
 * 
 * The DDLogLevelsConfig provides an alternative to hard-coding the log levels within the file itself.
 * Instead, a config file is used.
 * The config file for the release build is checked into the repository.
 * However, the config file for debugging is not checked into the repository, and each developer maintins their own.
 * 
 * ddLogLevel = [[DDLogLevelsConfig config:@"debug.log"] levelFor:THIS_FILE];
**/

#import <Foundation/Foundation.h>

@protocol DDLogLevelsConfigReader;


@interface DDLogLevelsConfig : NSObject {
@private
	dispatch_queue_t configInstanceQueue;
	
	NSString *filePath;
	NSMutableDictionary *levels;
}

+ (DDLogLevelsConfig *)config:(NSString *)fileName;

- (int)levelFor:(NSString *)fileName;
- (int)levelFor:(NSString *)fileName withDefault:(int)valueIfNotPresent;

@end

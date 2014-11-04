#import "LogLevelsConfigFileAppDelegate.h"
#import "DDLogLevelsConfig.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "Lions.h"
#import "Tigers.h"
#import "Bears.h"

#import <objc/runtime.h>

#define DEV_ROBBIE 1
#define DEV_MARIUS 2

#define DDLOG_DEV_NAME DEV_MARIUS

#if DDLOG_DEV_NAME == DEV_ROBBIE
  static int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
  static int ddLogLevel = LOG_LEVEL_ERROR;
#endif




@implementation LogLevelsConfigFileAppDelegate

@synthesize window;

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
	#ifdef DEBUG
	//	ddLogLevel = [[DDLogLevelsConfig config:@"DebugLogging.txt"] levelFor:THIS_FILE];
	#else
	//	ddLogLevel = [[DDLogLevelsConfig config:@"ReleaseLogging.txt"] levelFor:THIS_FILE];
	#endif
	});
}

+ (void)printLogStatements
{
	DDLogError(@"%@ - Error", THIS_FILE);
	DDLogWarn(@"%@ - Warn", THIS_FILE);
	DDLogInfo(@"%@ - Info", THIS_FILE);
	DDLogVerbose(@"%@ - Verbose", THIS_FILE);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	ass
#ifdef CUSTOM_MACRO
	NSLog(@"CUSTOM_MACRO defined!!!");
#else
	NSLog(@"CUSTOM_MACRO not defined");
#endif
	
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
//	[[self class] printLogStatements];
//	[Lions  printLogStatements];
//	[Tigers printLogStatements];
//	[Bears  printLogStatements];
}



@end

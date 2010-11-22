#import "RollingTestMacAppDelegate.h"

#import "DDLog.h"
#import "DDFileLogger.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation RollingTestMacAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	fileLogger = [[DDFileLogger alloc] init];
	
	fileLogger.maximumFileSize = 1024 * 1;  //  1 KB
	fileLogger.rollingFrequency = 60;       // 60 Seconds
	
	fileLogger.logFileManager.maximumNumberOfLogFiles = 4;
	
	[DDLog addLogger:fileLogger];
	
	[NSTimer scheduledTimerWithTimeInterval:1.0
									 target:self
								   selector:@selector(fillLogFiles:)
								   userInfo:nil
									repeats:YES];
}

- (void)fillLogFiles:(NSTimer *)aTimer
{
	int max = 1;
	
	// To test rolling log files due to age, set max to 1
	// To test rolling log files due to size, set max to 10
	
	for (int i = 0; i < max; i++)
	{
		DDLogInfo(@"I like cheese");
	}
	
	NSLog(@"Inc");
}

@end

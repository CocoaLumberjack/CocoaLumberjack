#import "FineGrainedLoggingAppDelegate.h"

#import "MYLog.h"
#import "DDConsoleLogger.h"

#import "TimerOne.h"
#import "TimerTwo.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation FineGrainedLoggingAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[DDLog addLogger:[DDConsoleLogger sharedInstance]];
	
	timerOne = [[TimerOne alloc] init];
	timerTwo = [[TimerTwo alloc] init];
}

@end

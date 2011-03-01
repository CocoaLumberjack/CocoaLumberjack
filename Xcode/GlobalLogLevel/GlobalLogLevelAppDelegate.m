#import "GlobalLogLevelAppDelegate.h"
#import "Stuff.h"
#import "MyLogging.h"
#import "DDTTYLogger.h"

int ddLogLevel;

@implementation GlobalLogLevelAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	ddLogLevel = LOG_LEVEL_VERBOSE;
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	DDLogError(@"%@: Error", THIS_FILE);
	DDLogWarn(@"%@: Warn", THIS_FILE);
	DDLogInfo(@"%@: Info", THIS_FILE);
	DDLogVerbose(@"%@: Verbose", THIS_FILE);
	
	ddLogLevel = LOG_LEVEL_WARN;
	
	[Stuff doStuff];
}

@end

#import "CustomLogLevelsAppDelegate.h"

#import "MYLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

// Debug levels: off, fatal, error, warn, notice, info, debug
static const int ddLogLevel = LOG_LEVEL_DEBUG;


@implementation CustomLogLevelsAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	DDLogFatal(@"Fatal");
	DDLogError(@"Error");
	DDLogWarn(@"Warn");
	DDLogNotice(@"Notice");
	DDLogInfo(@"Info");
	DDLogDebug(@"Debug");
}

@end

#import "AppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// Standard lumberjack initialization
	
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	// And we're going to enable colors
	
	[[DDTTYLogger sharedInstance] setColorsEnabled:YES];
	
	// Check out default colors:
	// Error : Red
	// Warn  : Orange
	
	DDLogError(@"Paper jam");
	DDLogWarn(@"Toner is low");
	DDLogInfo(@"Warming up printer (pre-customization)");
	DDLogVerbose(@"Intializing protcol x26");
	
	// Now let's do some customization:
	// Info  : Pink
	
	NSColor *pink = [NSColor colorWithCalibratedRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
	
	[[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:LOG_FLAG_INFO];
	
	DDLogInfo(@"Warming up printer (post-customization)");
}

@end

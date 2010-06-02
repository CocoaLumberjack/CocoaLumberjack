#import "CustomFormattersAppDelegate.h"

#import "DDLog.h"
#import "DDConsoleLogger.h"
#import "TestFormatter.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation CustomFormattersAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Setup logging (with our custom formatter)
	
	TestFormatter *formatter = [[[TestFormatter alloc] init] autorelease];
	[[DDConsoleLogger sharedInstance] setLogFormatter:formatter];
	
	[DDLog addLogger:[DDConsoleLogger sharedInstance]];
	
	// Log some messages
	
	DDLogError(@"Paper Jam!");
	DDLogWarn(@"Low toner");
	DDLogInfo(@"Printing SalesProjections.doc");
	DDLogVerbose(@"Warming up toner");
}

@end

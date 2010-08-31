#import "CustomFormattersAppDelegate.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "TestFormatter.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation CustomFormattersAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Setup logging (with our custom formatter)
	
	TestFormatter *formatter = [[[TestFormatter alloc] init] autorelease];
	
	[[DDASLLogger sharedInstance] setLogFormatter:formatter];
	[[DDTTYLogger sharedInstance] setLogFormatter:formatter];
	
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	// Log some messages
	
	DDLogError(@"Paper Jam!");
	DDLogWarn(@"Low toner");
	DDLogInfo(@"Printing SalesProjections.doc");
	DDLogVerbose(@"Warming up toner");
}

@end

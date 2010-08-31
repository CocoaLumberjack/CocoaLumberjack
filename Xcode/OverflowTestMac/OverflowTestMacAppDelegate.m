#import "OverflowTestMacAppDelegate.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "SlowLogger.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation OverflowTestMacAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"How to use this test:");
	NSLog(@"1. Set the DEBUG definition to YES in DDLog.m");
	NSLog(@"2. Set the LOG_MAX_QUEUE_SIZE definition to 5 in DDLog.m\n\n");
	
	SlowLogger *slowLogger = [[[SlowLogger alloc] init] autorelease];
	[DDLog addLogger:slowLogger];
	
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	[NSThread detachNewThreadSelector:@selector(bgThread1) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(bgThread2) toTarget:self withObject:nil];
	
	NSLog(@"mainThread");
	
	for (int i = 0; i < 10; i++)
	{
		DDLogVerbose(@"mainThread: %i", i);
	}
	
	[DDLog flushLog];
}

- (void)bgThread1
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"bgThread1");
	
	for (int i = 0; i < 10; i++)
	{
		DDLogVerbose(@"bgThread1 : %i", i);
	}
	
	[pool release];
}

- (void)bgThread2
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"bgThread2");
	
	for (int i = 0; i < 10; i++)
	{
		DDLogVerbose(@"bgThread2 : %i", i);
	}
	
	[pool release];
}

@end

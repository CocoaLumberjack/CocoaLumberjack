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
	// Since logging can be asynchronous, its possible for rogue threads to flood the logging queue.
	// That is, to issue an abundance of log statements faster than the logging thread can keepup.
	// Typically such a scenario occurs when log statements are added haphazardly within large loops,
	// but may also be possible if relatively slow loggers are being used.
	// 
	// Lumberjack has the ability to cap the queue size at a given number of outstanding log statements.
	// If a thread attempts to issue a log statement when the queue is already maxed out,
	// the issuing thread will block until the queue size drops below the max again.
	// 
	// This Xcode project demonstrates this feature by using a "Slow Logger".
	
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

#import "TimerOne.h"
#import "MYLog.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE | LOG_FLAG_TIMERS;


@implementation TimerOne

- (id)init
{
	if ((self = [super init]))
	{
		DDLogVerbose(@"TimerOne: Creating timers...");
		
		foodTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0
													  target:self
													selector:@selector(foodTimerDidFire:)
													userInfo:nil
													 repeats:YES] retain];
		
		sleepTimer = [[NSTimer scheduledTimerWithTimeInterval:6.0
													   target:self
													 selector:@selector(sleepTimerDidFire:)
													 userInfo:nil
													  repeats:YES] retain];
	}
	return self;
}

- (void)foodTimerDidFire:(NSTimer *)aTimer
{
	DDLogFoodTimer(@"TimerOne: Hungry - Need Food");
}

- (void)sleepTimerDidFire:(NSTimer *)aTimer
{
	DDLogSleepTimer(@"TimerOne: Tired - Need Sleep");
}

- (void)dealloc
{
	DDLogVerbose(@"TimerOne: dealloc");
	
	[foodTimer invalidate];
	[foodTimer release];
	
	[sleepTimer invalidate];
	[sleepTimer release];
	
	[super dealloc];
}

@end

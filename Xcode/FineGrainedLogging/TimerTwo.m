#import "TimerTwo.h"
#import "MYLog.h"

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE | LOG_FLAG_TIMERS;


@implementation TimerTwo

- (id)init
{
	if ((self = [super init]))
	{
		DDLogVerbose(@"TimerTwo: Creating timers...");
		
		foodTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0
													  target:self
													selector:@selector(foodTimerDidFire:)
													userInfo:nil
													 repeats:YES] retain];
		
		sleepTimer = [[NSTimer scheduledTimerWithTimeInterval:30.0
													   target:self
													 selector:@selector(sleepTimerDidFire:)
													 userInfo:nil
													  repeats:YES] retain];
	}
	return self;
}

- (void)foodTimerDidFire:(NSTimer *)aTimer
{
	DDLogFoodTimer(@"TimerTwo: Hungry - Need Food");
}

- (void)sleepTimerDidFire:(NSTimer *)aTimer
{
	DDLogSleepTimer(@"TimerTwo: Tired - Need Sleep");
}

- (void)dealloc
{
	DDLogVerbose(@"TimerTwo: dealloc");
	
	[foodTimer invalidate];
	[foodTimer release];
	
	[sleepTimer invalidate];
	[sleepTimer release];
	
	[super dealloc];
}

@end

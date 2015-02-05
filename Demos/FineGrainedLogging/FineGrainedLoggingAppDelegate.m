#import "FineGrainedLoggingAppDelegate.h"

#import "MYLog.h"

#import "TimerOne.h"
#import "TimerTwo.h"

// Debug levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation FineGrainedLoggingAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelVerbose | LOG_FLAG_TIMERS];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelVerbose | LOG_FLAG_TIMERS];
    
    timerOne = [[TimerOne alloc] init];
    timerTwo = [[TimerTwo alloc] init];
}

@end

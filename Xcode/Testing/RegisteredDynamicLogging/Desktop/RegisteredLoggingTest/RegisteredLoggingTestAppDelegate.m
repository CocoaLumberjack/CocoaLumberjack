#import "RegisteredLoggingTestAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "Lions.h"
#import "Tigers.h"

// Log levels: off, error, warn, info, verbose
static int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation RegisteredLoggingTestAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [Lions logStuff];
    [Tigers logStuff];
    
    NSArray *registeredClassNames = [DDLog registeredClassNames];
    DDLogVerbose(@"registeredClassNames: %@", registeredClassNames);
    
    NSArray *registeredClasses = [DDLog registeredClasses];
    for (Class class in registeredClasses)
    {
        [class ddSetLogLevel:LOG_LEVEL_VERBOSE];
    }
    
    [Lions logStuff];
    [Tigers logStuff];
}

@end

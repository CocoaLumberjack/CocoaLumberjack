#import "GlobalLogLevelAppDelegate.h"
#import "Stuff.h"
#import "MyLogging.h"
#import "DDTTYLogger.h"

int ddLogLevel;

@implementation GlobalLogLevelAppDelegate

@synthesize window;

void someFunction()
{
    DDLogCError(@"%@: C_Error", THIS_FILE);
    DDLogCWarn(@"%@: C_Warn", THIS_FILE);
    DDLogCInfo(@"%@: C_Info", THIS_FILE);
    DDLogCVerbose(@"%@: C_Verbose", THIS_FILE);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ddLogLevel = LOG_LEVEL_VERBOSE;
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDLogError(@"%@: Error", THIS_FILE);
    DDLogWarn(@"%@: Warn", THIS_FILE);
    DDLogInfo(@"%@: Info", THIS_FILE);
    DDLogVerbose(@"%@: Verbose", THIS_FILE);
    
    someFunction();
    
    ddLogLevel = LOG_LEVEL_WARN;
    
    [Stuff doStuff];
}

@end

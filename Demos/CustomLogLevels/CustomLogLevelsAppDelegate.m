#import "CustomLogLevelsAppDelegate.h"

#import "MYLog.h"

// Debug levels: off, fatal, error, warn, notice, info, debug
static const DDLogLevel ddLogLevel = DDLogLevelDebug;


@implementation CustomLogLevelsAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // since the verbose log level was undefined, we need to specify the log level for every logger
    [DDLog addLogger:[DDASLLogger sharedInstance] withLogLevel:DDLogLevelDebug];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:DDLogLevelDebug];
    
    DDLogFatal(@"Fatal");
    DDLogError(@"Error");
    DDLogWarn(@"Warn");
    DDLogNotice(@"Notice");
    DDLogInfo(@"Info");
    DDLogDebug(@"Debug");
}

@end

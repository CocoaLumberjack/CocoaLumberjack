#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDTTYLogger.h>

// Log levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDLogVerbose(@"Verbose");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");
    
    DDLog *aDDLogInstance = [DDLog new];
    [aDDLogInstance addLogger:[DDTTYLogger sharedInstance]];
    
    DDLogVerboseToDDLog(aDDLogInstance, @"Verbose from aDDLogInstance");
    DDLogInfoToDDLog(aDDLogInstance, @"Info from aDDLogInstance");
    DDLogWarnToDDLog(aDDLogInstance, @"Warn from aDDLogInstance");
    DDLogErrorToDDLog(aDDLogInstance, @"Error from aDDLogInstance");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

}

@end

//
//  CustomLogLevelsAppDelegate.m
//  CustomLogLevels
//
//  CocoaLumberjack Demos
//

#import "CustomLogLevelsAppDelegate.h"

#import "MYLog.h"

// Debug levels: off, fatal, error, warn, notice, info, debug
static const DDLogLevel ddLogLevel = LOG_LEVEL_DEBUG;

@implementation CustomLogLevelsAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // since the verbose log level was undefined, we need to specify the log level for every logger
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:LOG_LEVEL_DEBUG];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:LOG_LEVEL_DEBUG];
    
    DDLogFatal(@"Fatal");
    DDLogError(@"Error");
    DDLogWarn(@"Warn");
    DDLogNotice(@"Notice");
    DDLogInfo(@"Info");
    DDLogDebug(@"Debug");
}

@end

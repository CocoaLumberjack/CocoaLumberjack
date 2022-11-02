//
//  AppDelegate.m
//  NonArcTest
//
//  CocoaLumberjack Demos
//

#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

// Log levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    [DDLog addLogger:(id<DDLogger>)[DDTTYLogger sharedInstance]];
    
    DDLogVerbose(@"Testing");
}

@end

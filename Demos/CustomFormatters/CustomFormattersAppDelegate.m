//
//  CustomFormattersAppDelegate.m
//  CustomFormatters
//
//  CocoaLumberjack Demos
//

#import "CustomFormattersAppDelegate.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "TestFormatter.h"

// Debug levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation CustomFormattersAppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Setup logging (with our custom formatter)
    
    TestFormatter *formatter = [[TestFormatter alloc] init];
    
    [[DDOSLogger sharedInstance] setLogFormatter:formatter];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
    
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    [DDLog addLogger:(id<DDLogger>)[DDTTYLogger sharedInstance]];
    
    // Log some messages
    
    DDLogError(@"Paper Jam!");
    DDLogWarn(@"Low toner");
    DDLogInfo(@"Printing SalesProjections.doc");
    DDLogVerbose(@"Warming up toner");
}

@end

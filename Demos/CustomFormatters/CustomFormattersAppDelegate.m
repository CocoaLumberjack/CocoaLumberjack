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
    
    [[DDASLLogger sharedInstance] setLogFormatter:formatter];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Log some messages
    
    DDLogError(@"Paper Jam!");
    DDLogWarn(@"Low toner");
    DDLogInfo(@"Printing SalesProjections.doc");
    DDLogVerbose(@"Warming up toner");
}

@end

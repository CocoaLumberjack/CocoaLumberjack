//
//  GlobalLogLevelAppDelegate.m
//  GlobalLogLevel
//
//  CocoaLumberjack Demos
//

#import "GlobalLogLevelAppDelegate.h"
#import "Stuff.h"
#import "MyLogging.h"

DDLogLevel ddLogLevel;

@implementation GlobalLogLevelAppDelegate
@synthesize window;

static void someFunction()
{
    DDLogError(@"%@: C_Error", THIS_FILE);
    DDLogWarn(@"%@: C_Warn", THIS_FILE);
    DDLogInfo(@"%@: C_Info", THIS_FILE);
    DDLogVerbose(@"%@: C_Verbose", THIS_FILE);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ddLogLevel = DDLogLevelVerbose;
    [DDLog addLogger:(id<DDLogger>)[DDTTYLogger sharedInstance]];
    
    DDLogError(@"%@: Error", THIS_FILE);
    DDLogWarn(@"%@: Warn", THIS_FILE);
    DDLogInfo(@"%@: Info", THIS_FILE);
    DDLogVerbose(@"%@: Verbose", THIS_FILE);
    
    someFunction();
    
    ddLogLevel = DDLogLevelWarning;
    
    [Stuff doStuff];
}

@end

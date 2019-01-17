//
//  RegisteredLoggingTestAppDelegate.m
//  RegisteredLoggingTest
//
//  CocoaLumberjack Demos
//

#import "RegisteredLoggingTestAppDelegate.h"
#import "RegisteredLoggingTestViewController.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "Lions.h"
#import "Tigers.h"

// Log levels: off, error, warn, info, verbose
static DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation RegisteredLoggingTestAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [Lions logStuff];
    [Tigers logStuff];
    
    NSArray *registeredClassNames = [DDLog registeredClassNames];
    DDLogVerbose(@"registeredClassNames: %@", registeredClassNames);
    
    NSArray *registeredClasses = [DDLog registeredClasses];
    for (Class class in registeredClasses)
    {
        [class ddSetLogLevel:DDLogLevelVerbose];
    }
    
    [Lions logStuff];
    [Tigers logStuff];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

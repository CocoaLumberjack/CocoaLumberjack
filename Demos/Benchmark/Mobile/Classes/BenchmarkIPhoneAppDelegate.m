//
//  BenchmarkIPhoneAppDelegate.m
//  BenchmarkIPhone
//
//  CocoaLumberjack Demos
//

#import "BenchmarkIPhoneAppDelegate.h"
#import "BenchmarkIPhoneViewController.h"
#import "PerformanceTesting.h"

@implementation BenchmarkIPhoneAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    window.rootViewController = viewController;
    [window makeKeyAndVisible];
    
    [PerformanceTesting startPerformanceTests];
}

@end

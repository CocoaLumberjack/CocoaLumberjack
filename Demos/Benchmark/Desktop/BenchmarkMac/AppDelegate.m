//
//  AppDelegate.m
//  BenchmarkMac
//
//  CocoaLumberjack Demos
//

#import "AppDelegate.h"
#import "PerformanceTesting.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [PerformanceTesting startPerformanceTests];
}

@end

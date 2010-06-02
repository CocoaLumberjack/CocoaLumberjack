#import "BenchmarkIPhoneAppDelegate.h"
#import "BenchmarkIPhoneViewController.h"
#import "PerformanceTesting.h"


@implementation BenchmarkIPhoneAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	[PerformanceTesting startPerformanceTests];
}

- (void)dealloc
{
	[viewController release];
	[window release];
	[super dealloc];
}

@end

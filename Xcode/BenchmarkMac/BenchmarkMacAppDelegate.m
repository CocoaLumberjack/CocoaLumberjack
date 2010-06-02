#import "BenchmarkMacAppDelegate.h"
#import "PerformanceTesting.h"


@implementation BenchmarkMacAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[PerformanceTesting startPerformanceTests];
}

@end

#import "CoreDataLoggerAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "CoreDataLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation CoreDataLoggerAppDelegate

@synthesize window;

- (NSString *)applicationFilesDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    return [basePath stringByAppendingPathComponent:@"CoreDataLogger"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//  [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    coreDataLogger = [[CoreDataLogger alloc] initWithLogDirectory:[self applicationFilesDirectory]];
    
    coreDataLogger.saveThreshold     = 500;
    coreDataLogger.saveInterval      = 60;               // 60 seconds
    coreDataLogger.maxAge            = 60 * 60 * 24 * 7; //  7 days
    coreDataLogger.deleteInterval    = 60 * 5;           //  5 minutes
    coreDataLogger.deleteOnEverySave = NO;
    
    [DDLog addLogger:coreDataLogger];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(doTest:) userInfo:nil repeats:NO];
}

- (void)doTest:(NSTimer *)aTimer
{
    NSDate *start = [NSDate date];
    
    int i;
    for (i = 0; i < 1000; i++)
    {
        DDLogVerbose(@"A log message of average size");
    }
    [DDLog flushLog];
    
    NSTimeInterval elapsed = [start timeIntervalSinceNow] * -1.0;
    NSLog(@"Total time: %.4f", elapsed);
}

@end

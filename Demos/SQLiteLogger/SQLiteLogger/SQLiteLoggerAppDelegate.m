//
//  SQLiteLoggerAppDelegate.m
//  SQLiteLogger
//
//  CocoaLumberjack Demos
//

#import "SQLiteLoggerAppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "FMDBLogger.h"

// Log levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation SQLiteLoggerAppDelegate

@synthesize window;

- (NSString *)applicationFilesDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    return [basePath stringByAppendingPathComponent:@"SQLiteLogger"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//  [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    sqliteLogger = [[FMDBLogger alloc] initWithLogDirectory:[self applicationFilesDirectory]];
    
    sqliteLogger.saveThreshold     = 500;
    sqliteLogger.saveInterval      = 60;               // 60 seconds
    sqliteLogger.maxAge            = 60 * 60 * 24 * 7; //  7 days
    sqliteLogger.deleteInterval    = 60 * 5;           //  5 minutes
    sqliteLogger.deleteOnEverySave = NO;
    
    [DDLog addLogger:sqliteLogger];
    
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

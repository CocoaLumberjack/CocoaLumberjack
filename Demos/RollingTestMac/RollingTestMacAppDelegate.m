//
//  RollingTestMacAppDelegate.m
//  RollingTestMac
//
//  CocoaLumberjack Demos
//

#import "RollingTestMacAppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

// Debug levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation RollingTestMacAppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    fileLogger = [[DDFileLogger alloc] init];
    
    fileLogger.maximumFileSize = 1024 * 1;  //  1 KB
    fileLogger.rollingFrequency = 60;       // 60 Seconds
    
    fileLogger.logFileManager.maximumNumberOfLogFiles = 4;
    
    [DDLog addLogger:fileLogger];
    
    // Test auto log file roll
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(fillLogFiles:)
                                   userInfo:nil
                                    repeats:YES];
    
    // Test forced log file roll
    
//  DDLogInfo(@"Log file 1 : Log message 1");
//  DDLogInfo(@"Log file 1 : Log message 2");
//  DDLogInfo(@"Log file 1 : Log message 3");
//  
//  [fileLogger rollLogFile];
//  
//  DDLogInfo(@"Log file 2 : Log message 1");
//  DDLogInfo(@"Log file 2 : Log message 2");
//  DDLogInfo(@"Log file 2 : Log message 3");
}

- (void)fillLogFiles:(NSTimer *)aTimer
{
    int max = 1;
    
    // To test rolling log files due to age, set max to 1
    // To test rolling log files due to size, set max to 10
    
    for (int i = 0; i < max; i++)
    {
        DDLogInfo(@"I like cheese");
    }
    
    NSLog(@"Inc");
}

@end

//
//  LogFileCompressorAppDelegate.m
//  LogFileCompressor
//
//  CocoaLumberjack Demos
//

#import "LogFileCompressorAppDelegate.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "CompressingLogFileManager.h"

// Debug levels: off, error, warn, info, verbose
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation LogFileCompressorAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CompressingLogFileManager *logFileManager = [[CompressingLogFileManager alloc] init];
    
    fileLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    
    fileLogger.maximumFileSize  = 1024 * 1;  // 1 KB
    fileLogger.rollingFrequency =   60 * 1;  // 1 Minute
    
    fileLogger.logFileManager.maximumNumberOfLogFiles = 4;
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:fileLogger];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(writeLogMessages:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)writeLogMessages:(NSTimer *)aTimer
{
    DDLogVerbose(@"I like cheese");
}

@end

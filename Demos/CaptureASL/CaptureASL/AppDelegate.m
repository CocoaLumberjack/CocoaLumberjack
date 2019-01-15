//
//  AppDelegate.m
//  CaptureASL
//
//  CocoaLumberjack Demos
//

#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface SimpleFormatter : NSObject <DDLogFormatter>

@end

@implementation SimpleFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    return [NSString stringWithFormat:@"  Captured: %@", logMessage->_message];
}

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DDTTYLogger.sharedInstance.logFormatter = [SimpleFormatter new];
    [DDLog addLogger:DDTTYLogger.sharedInstance];
    [DDLog addLogger:DDASLLogger.sharedInstance];
    
    [DDASLLogCapture start];
    
    return YES;
}
							
@end

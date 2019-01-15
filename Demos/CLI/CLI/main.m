//
//  main.m
//  CLI
//
//  CocoaLumberjack Demos
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        // Test
        DDTTYLogger * logger = [DDTTYLogger sharedInstance];
        logger.colorsEnabled = YES;
        [logger setForegroundColor:[DDColor colorWithCalibratedRed:26.0/255.0
                                                              green:158.0/255.0
                                                               blue:4.0/255.0
                                                              alpha:1.0]
                   backgroundColor:nil
                           forFlag:DDLogFlagInfo];
        [DDLog addLogger:logger];
        DDLogInfo(@"Hello, World!");
    }
    return 0;
}

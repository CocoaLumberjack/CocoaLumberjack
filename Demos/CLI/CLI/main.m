//
//  main.m
//  CLI
//
//  Created by Ernesto Rivera on 2013/12/19.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "../Pods-CLI_osx-environment.h"
#import <CocoaLumberjack/DDTTYLogger.h>

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        // Test
        DDTTYLogger * logger = [DDTTYLogger sharedInstance];
        logger.colorsEnabled = YES;
        [logger setForegroundColor:[CLIColor colorWithCalibratedRed:26.0/255.0
                                                              green:158.0/255.0
                                                               blue:4.0/255.0
                                                              alpha:1.0]
                   backgroundColor:nil
                           forFlag:LOG_FLAG_INFO];
        [DDLog addLogger:logger];
        DDLogInfo(@"Hello, World!");
    }
    return 0;
}


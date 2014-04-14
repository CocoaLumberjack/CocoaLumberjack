//
//  main.m
//  CLI
//
//  Created by 利辺羅 on 2013/12/19.
//  Copyright (c) 2013年 CyberAgent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDLog.h>
#import "../Pods-environment.h"
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
        DDLogCInfo(@"Hello, World!");
    }
    return 0;
}


//
//  LogEntriesLogger.m
//  Where's the Beef
//
//  Created by Craig Hughes on 12/12/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "LogEntriesLogger.h"

#import "lelib.h"

@implementation LogEntriesLogger

- (instancetype)initWithLogEntriesToken:(NSString *)token
{
    self = [super init];

    [LELog sharedInstance].token = token;

    return self;
}

- (void)setLogEntriesToken:(NSString *)logEntriesToken
{
    [LELog sharedInstance].token = logEntriesToken;
}

- (NSString *)logEntriesToken
{
    return [LELog sharedInstance].token;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    NSString *logMsg = logMessage.message;

    if (_logFormatter)
    {
        logMsg = [_logFormatter formatLogMessage:logMessage];
    }

    if (logMsg)
    {
        [[LELog sharedInstance] log:logMsg];
    }
}

@end

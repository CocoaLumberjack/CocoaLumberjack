//
//  LogEntriesLogFormatter.m
//  Where's the Beef
//
//  Created by Craig Hughes on 12/12/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "HelpfulInfoLogFormatter.h"

@implementation HelpfulInfoLogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *timestamp = [self stringFromDate:(logMessage->_timestamp)];
    NSString *queueThreadLabel = [self queueThreadLabelForLogMessage:logMessage];

    char logLevel;

    switch (logMessage->_flag)
    {
        case DDLogFlagError:
            logLevel = 'E';
            break;
        case DDLogFlagWarning:
            logLevel = 'W';
            break;
        case DDLogFlagInfo:
            logLevel = 'I';
            break;
        case DDLogFlagDebug:
            logLevel = 'D';
            break;
        case DDLogFlagVerbose:
            logLevel = 'V';
            break;
        default:
            logLevel = '?';
    }

    return [NSString stringWithFormat:@"%c (%@.m:%lu) %@ [%@] %@",
                                logLevel,
                                logMessage->_fileName,
                                (unsigned long)logMessage->_line,
                                timestamp,
                                queueThreadLabel,
                                logMessage->_message];
}


@end

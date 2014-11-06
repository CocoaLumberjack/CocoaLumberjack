#import "TestFormatter.h"


/**
 * For more information about creating custom formatters, see the wiki article:
 * https://github.com/CocoaLumberjack/CocoaLumberjack/wiki/CustomFormatters
**/
@implementation TestFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    return [NSString stringWithFormat:@"%@ | %@ @ %@ | %@",
            [logMessage fileName], logMessage->_function, @(logMessage->_line), logMessage->_message];
}

@end

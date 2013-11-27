#import "TestFormatter.h"


/**
 * For more information about creating custom formatters, see the wiki article:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomFormatters
**/
@implementation TestFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    return [NSString stringWithFormat:@"%@ | %s @ %i | %@",
            [logMessage fileName], logMessage->function, logMessage->lineNumber, logMessage->logMsg];
}

@end

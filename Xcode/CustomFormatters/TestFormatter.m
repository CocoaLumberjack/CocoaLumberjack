#import "TestFormatter.h"


@implementation TestFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	return [NSString stringWithFormat:@"%@ | %s @ %i | %@",
			[logMessage fileName], logMessage->function, logMessage->lineNumber, logMessage->logMsg];
}

@end

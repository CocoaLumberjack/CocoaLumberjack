#import "SlowLogger.h"


@implementation SlowLogger

- (void)logMessage:(DDLogMessage *)logMessage
{
	[NSThread sleepForTimeInterval:0.25];
}

- (id <DDLogFormatter>)logFormatter
{
	return nil;
}

- (void)setLogFormatter:(id <DDLogFormatter>)logFormatter
{
	// Not supported
}

@end

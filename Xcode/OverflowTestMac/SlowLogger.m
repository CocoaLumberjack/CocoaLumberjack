#import "SlowLogger.h"


@implementation SlowLogger

- (void)logMessage:(DDLogMessage *)logMessage
{
    [NSThread sleepForTimeInterval:0.25];
}

@end

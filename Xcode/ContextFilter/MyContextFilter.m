#import "MyContextFilter.h"
#import "ThirdPartyFramework.h"


@implementation MyContextFilter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    if (logMessage->logContext == TP_LOG_CONTEXT)
    {
        // We can filter this message by simply returning nil
        return nil;
    }
    else
    {
        // We could format this message if we wanted to here.
        // But this example is just about filtering.
        return logMessage->logMsg;
    }
}

@end

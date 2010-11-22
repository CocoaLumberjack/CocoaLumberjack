#import "ThirdPartyFramework.h"
#import "DDLog.h"

// Third party frameworks and libraries should define their own custom log definitions.
// These should use a custom context to allow those who use the framework
// the ability to maintain fine grained control of their logging experience.
// 
// The custom context is defined in the header file:
// 
// #define TP_LOG_CONTEXT 1044

#define TP_LOG_ERROR   (tpLogLevel & LOG_FLAG_ERROR)
#define TP_LOG_WARN    (tpLogLevel & LOG_FLAG_WARN)
#define TP_LOG_INFO    (tpLogLevel & LOG_FLAG_INFO)
#define TP_LOG_VERBOSE (tpLogLevel & LOG_FLAG_VERBOSE)

#define TPLogError(frmt, ...)     SYNC_LOG_OBJC_MAYBE(tpLogLevel, LOG_FLAG_ERROR,   TP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define TPLogWarn(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(tpLogLevel, LOG_FLAG_WARN,    TP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define TPLogInfo(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(tpLogLevel, LOG_FLAG_INFO,    TP_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define TPLogVerbose(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(tpLogLevel, LOG_FLAG_VERBOSE, TP_LOG_CONTEXT, frmt, ##__VA_ARGS__)

// Log levels: off, error, warn, info, verbose
static const int tpLogLevel = LOG_LEVEL_VERBOSE;


@implementation ThirdPartyFramework

+ (void)start
{
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fire:) userInfo:nil repeats:YES];
}

+ (void)fire:(NSTimer *)timer
{
	TPLogVerbose(@"Log message from third party framework");
}

@end

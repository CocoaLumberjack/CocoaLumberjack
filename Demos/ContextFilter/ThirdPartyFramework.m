//
//  ThirdPartyFramework.m
//  ContextFilter
//
//  CocoaLumberjack Demos
//

#import "ThirdPartyFramework.h"
#import <CocoaLumberjack/DDLogMacros.h>

// Third party frameworks and libraries should define their own custom log definitions.
// These should use a custom context to allow those who use the framework
// the ability to maintain fine grained control of their logging experience.
// 
// The custom context is defined in the header file:
// 

#define TP_LOG_CONTEXT 1044

#define TPLogError(frmt, ...)   LOG_MAYBE(NO,                tpLogLevel, DDLogFlagError,   TP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define TPLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, tpLogLevel, DDLogFlagWarning, TP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define TPLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, tpLogLevel, DDLogFlagInfo,    TP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define TPLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, tpLogLevel, DDLogFlagDebug,   TP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define TPLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, tpLogLevel, DDLogFlagVerbose, TP_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

// Log levels: off, error, warn, info, verbose
static const int tpLogLevel = DDLogLevelVerbose;


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

#import "Bears.h"
#import "DDLogLevelsConfig.h"
#import "DDLog.h"

static int ddLogLevel;


@implementation Bears

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		ddLogLevel = [[DDLogLevelsConfig config:@"DebugLogging.txt"] levelFor:THIS_FILE];
	});
}

+ (void)printLogStatements
{
	DDLogError(@"%@ - Error", THIS_FILE);
	DDLogWarn(@"%@ - Warn", THIS_FILE);
	DDLogInfo(@"%@ - Info", THIS_FILE);
	DDLogVerbose(@"%@ - Verbose", THIS_FILE);
}

@end

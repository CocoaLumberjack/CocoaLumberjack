#import "StaticLogging.h"
#import "PerformanceTesting.h"
#import "DDLog.h"

#define FILENAME @"StaticLogging " // Trailing space to match exactly the others in length

// Debug levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN; // CONST


@implementation StaticLogging

+ (void)speedTest0
{
	// Log statements that will not be executed due to log level
	
	for (NSUInteger i = 0; i < SPEED_TEST_0_COUNT; i++)
	{
		DDLogVerbose(@"%@: SpeedTest0 - %lu", FILENAME, (unsigned long)i);
	}
}

+ (void)speedTest1
{
	// Log statements that will be executed asynchronously
	
	for (NSUInteger i = 0; i < SPEED_TEST_1_COUNT; i++)
	{
		DDLogWarn(@"%@: SpeedTest1 - %lu", FILENAME, (unsigned long)i);
	}
}

+ (void)speedTest2
{
	// Log statements that will be executed synchronously
	
	for (NSUInteger i = 0; i < SPEED_TEST_2_COUNT; i++)
	{
		DDLogError(@"%@: SpeedTest2 - %lu", FILENAME, (unsigned long)i);
	}
}

+ (void)speedTest3
{
	// Even Spread:
	// 
	// 25% - Not executed due to log level
	// 50% - Executed asynchronously
	// 25% - Executed synchronously
	
	for (NSUInteger i = 0; i < SPEED_TEST_3_COUNT; i++)
	{
		DDLogError(@"%@: SpeedTest3A - %lu", FILENAME, (unsigned long)i);
	}
	for (NSUInteger i = 0; i < SPEED_TEST_3_COUNT; i++)
	{
		DDLogWarn(@"%@: SpeedTest3B - %lu", FILENAME, (unsigned long)i);
	}
	for (NSUInteger i = 0; i < SPEED_TEST_3_COUNT; i++)
	{
		DDLogInfo(@"%@: SpeedTest3C - %lu", FILENAME, (unsigned long)i);
	}
	for (NSUInteger i = 0; i < SPEED_TEST_3_COUNT; i++)
	{
		DDLogVerbose(@"%@: SpeedTest3D - %lu", FILENAME, (unsigned long)i);
	}
}

+ (void)speedTest4
{
	// Custom Spread
	
	for (NSUInteger i = 0; i < SPEED_TEST_4_ERROR_COUNT; i++)
	{
		DDLogError(@"%@: SpeedTest4A - %lu", FILENAME, (unsigned long)i);
	}
	for (NSUInteger i = 0; i < SPEED_TEST_4_WARN_COUNT; i++)
	{
		DDLogWarn(@"%@: SpeedTest4B - %lu", FILENAME, (unsigned long)i);
	}
	for (NSUInteger i = 0; i < SPEED_TEST_4_INFO_COUNT; i++)
	{
		DDLogInfo(@"%@: SpeedTest4C - %lu", FILENAME, (unsigned long)i);
	}
	for (NSUInteger i = 0; i < SPEED_TEST_4_VERBOSE_COUNT; i++)
	{
		DDLogVerbose(@"%@: SpeedTest4D - %lu", FILENAME, (unsigned long)i);
	}
}

@end

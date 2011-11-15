#import "PerformanceTesting.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"


#import "BaseNSLogging.h"
#import "StaticLogging.h"
#import "DynamicLogging.h"

// Define the number of times each test is performed.
// Due to various factors, the execution time of each test run may vary quite a bit.
// Each test should be executed several times in order to arrive at a stable average.
#define NUMBER_OF_RUNS 20

/**
 * The idea behind the benchmark tests is simple:
 * How does the logging framework compare to basic NSLog statements?
 * 
 * However, due to the complexity of the logging framework and its various configuration options,
 * it is more complicated than a single test.  Thus the testing is broken up as follows:
 * 
 * - 3 Suites, each representing a different configuration of the logging framework
 * - 5 Tests, run within each suite.
 * 
 * The suites are described below in the configureLoggingForSuiteX methods.
 * The tests are described in the various logging files, such as StaticLogging or DynamicLogging.
 * Notice that these file are almost exactly the same.
 * 
 * BaseNSLogging defines the log methods to use NSLog (the base we are comparing against).
 * StaticLogging uses a 'const' log level, meaning the compiler will prune log statements (in release mode).
 * DynamicLogging use a non-const log level, meaning each log statement will incur an integer comparison penalty.
**/

@implementation PerformanceTesting

static NSTimeInterval base[5][3]; // [test][min,avg,max]

static NSTimeInterval fmwk[3][2][5][3]; // [suite][file][test][min,avg,max]

static DDFileLogger *fileLogger = nil;

+ (void)initialize
{
	bzero(&base, sizeof(base));
	bzero(&fmwk, sizeof(fmwk));
}

+ (DDFileLogger *)fileLogger
{
	if (fileLogger == nil)
	{
		fileLogger = [[DDFileLogger alloc] init];
		
		fileLogger.maximumFileSize = (1024 * 1024 * 1); //  1 MB
		fileLogger.rollingFrequency = (60 * 60 * 24);   // 24 Hours
		
		fileLogger.logFileManager.maximumNumberOfLogFiles = 4;
	}
	
	return fileLogger;
}

/**
 * Suite 1 - Logging to Console only.
**/
+ (void)configureLoggingForSuite1
{
	[DDLog removeAllLoggers];
	
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
}

/**
 * Suite 2 - Logging to File only.
 * 
 * We attempt to configure the logging so it will be forced to roll the log files during the test.
 * Rolling the log files requires creating and opening a new file.
 * This could be a performance hit, so we want our benchmark to take this into account.
**/
+ (void)configureLoggingForSuite2
{
	[DDLog removeAllLoggers];
	
	[DDLog addLogger:[self fileLogger]];
}

/**
 * Suite 3 - Logging to Console & File.
**/
+ (void)configureLoggingForSuite3
{
	[DDLog removeAllLoggers];
	
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[self fileLogger]];
}

+ (void)executeTestsWithBase:(BOOL)exeBase framework:(BOOL)exeFramework frameworkSuite:(int)suiteNum
{
	if (!exeBase && !exeFramework) return;
	
	int sn = suiteNum - 1; // Zero-indexed for array
	
	int i, j, k;
	
	int start = exeBase ? 0 : 1;
	int finish = exeFramework ? 3 : 1;
	
	for (i = start; i < finish; i++)
	{
		Class class;
		switch (i)
		{
			case 0  : class = [BaseNSLogging  class]; break;
			case 1  : class = [StaticLogging  class]; break;
			default : class = [DynamicLogging class]; break;
		}
		
		for (j = 0; j < 5; j++)
		{
			NSTimeInterval min = DBL_MAX;
			NSTimeInterval max = DBL_MIN;
			
			NSTimeInterval total = 0.0;
			
			for (k = 0; k < NUMBER_OF_RUNS; k++)
			{
				@autoreleasepool {
				
					NSDate *start = [NSDate date];
					
					switch (j)
					{
						case 0  : [class performSelector:@selector(speedTest0)]; break;
						case 1  : [class performSelector:@selector(speedTest1)]; break;
						case 2  : [class performSelector:@selector(speedTest2)]; break;
						case 3  : [class performSelector:@selector(speedTest3)]; break;
						default : [class performSelector:@selector(speedTest4)]; break;
					}
					
					NSTimeInterval result = [start timeIntervalSinceNow] * -1.0;
					
					min = MIN(min, result);
					max = MAX(max, result);
					
					total += result;
				
				}
				[DDLog flushLog];
			}
			
			if (i == 0)
			{
				// Base
				base[j][0] = min;
				base[j][1] = total / (double)NUMBER_OF_RUNS;
				base[j][2] = max;
			}
			else
			{
				// Framework
				fmwk[sn][i-1][j][0] = min;
				fmwk[sn][i-1][j][1] = total / (double)NUMBER_OF_RUNS;
				fmwk[sn][i-1][j][2] = max;
			}
		}
	}
}

+ (NSString *)printableResultsForSuite:(int)suiteNum
{
	int sn = suiteNum - 1; // Zero-indexed for array
	
	NSMutableString *str = [NSMutableString stringWithCapacity:2000];
	
	[str appendFormat:@"Results are given as [min][avg][max] calculated over the course of %i runs.", NUMBER_OF_RUNS];
	[str appendString:@"\n\n"];
	
	[str appendString:@"Test 0:\n"];
	[str appendFormat:@"Execute %i log statements.\n", SPEED_TEST_0_COUNT];
	[str appendString:@"The log statement is above the log level threshold, and will not execute.\n"];
	[str appendString:@"The StaticLogging class will compile it out (in release mode).\n"];
	[str appendString:@"The DynamicLogging class will require a single integer comparison.\n"];
	[str appendString:@"\n"];
	[str appendFormat:@"BaseNSLogging :[%.4f][%.4f][%.4f]\n", base[0][0], base[0][1], base[0][2]];
	[str appendFormat:@"StaticLogging :[%.4f][%.4f][%.4f]\n", fmwk[sn][0][0][0], fmwk[sn][0][0][1], fmwk[sn][0][0][2]];
	[str appendFormat:@"DynamicLogging:[%.4f][%.4f][%.4f]\n", fmwk[sn][1][0][0], fmwk[sn][1][0][1], fmwk[sn][1][0][2]];
	[str appendString:@"\n\n\n"];
	
	[str appendString:@"Test 1:\n"];
	[str appendFormat:@"Execute %i log statements.\n", SPEED_TEST_1_COUNT];
	[str appendString:@"The log statement is at or below the log level threshold, and will execute.\n"];
	[str appendString:@"The logging framework will execute the statements Asynchronously.\n"];
	[str appendString:@"\n"];
	[str appendFormat:@"BaseNSLogging :[%.4f][%.4f][%.4f]\n", base[1][0], base[1][1], base[1][2]];
	[str appendFormat:@"StaticLogging :[%.4f][%.4f][%.4f]\n", fmwk[sn][0][1][0], fmwk[sn][0][1][1], fmwk[sn][0][1][2]];
	[str appendFormat:@"DynamicLogging:[%.4f][%.4f][%.4f]\n", fmwk[sn][1][1][0], fmwk[sn][1][1][1], fmwk[sn][1][1][2]];
	[str appendString:@"\n\n\n"];
	
	[str appendString:@"Test 2:\n"];
	[str appendFormat:@"Execute %i log statements.\n", SPEED_TEST_2_COUNT];
	[str appendString:@"The log statement is at or below the log level threshold, and will execute.\n"];
	[str appendString:@"The logging framework will execute the statements Synchronously.\n"];
	[str appendString:@"\n"];
	[str appendFormat:@"BaseNSLogging :[%.4f][%.4f][%.4f]\n", base[2][0], base[2][1], base[2][2]];
	[str appendFormat:@"StaticLogging :[%.4f][%.4f][%.4f]\n", fmwk[sn][0][2][0], fmwk[sn][0][2][1], fmwk[sn][0][2][2]];
	[str appendFormat:@"DynamicLogging:[%.4f][%.4f][%.4f]\n", fmwk[sn][1][2][0], fmwk[sn][1][2][1], fmwk[sn][1][2][2]];
	[str appendString:@"\n\n\n"];
	
	[str appendString:@"Test 3:"];
	[str appendFormat:@"Execute %i log statements per level.\n", SPEED_TEST_3_COUNT];
	[str appendString:@"This is designed to mimic what might happen in a regular application.\n"];
	[str appendString:@"25% will be above log level threshold and will be filtered out.\n"];
	[str appendString:@"50% will execute Asynchronously.\n"];
	[str appendString:@"25% will execute Synchronously.\n"];
	[str appendString:@"\n"];
	[str appendFormat:@"BaseNSLogging :[%.4f][%.4f][%.4f]\n", base[3][0], base[3][1], base[3][2]];
	[str appendFormat:@"StaticLogging :[%.4f][%.4f][%.4f]\n", fmwk[sn][0][3][0], fmwk[sn][0][3][1], fmwk[sn][0][3][2]];
	[str appendFormat:@"DynamicLogging:[%.4f][%.4f][%.4f]\n", fmwk[sn][1][3][0], fmwk[sn][1][3][1], fmwk[sn][1][3][2]];
	[str appendString:@"\n\n\n"];
	
	float total = 0.0F;
	total += SPEED_TEST_4_VERBOSE_COUNT;
	total += SPEED_TEST_4_INFO_COUNT;
	total += SPEED_TEST_4_WARN_COUNT;
	total += SPEED_TEST_4_ERROR_COUNT;
	
	float verbose = (float)SPEED_TEST_4_VERBOSE_COUNT / total * 100.0F;
	float info    = (float)SPEED_TEST_4_INFO_COUNT    / total * 100.0F;
	float warn    = (float)SPEED_TEST_4_WARN_COUNT    / total * 100.0F;
	float error   = (float)SPEED_TEST_4_ERROR_COUNT   / total * 100.0F;
	
	[str appendString:@"Test 4:\n"];
	[str appendString:@"Similar to test 3, designed to mimic a real application\n"];
	[str appendFormat:@"Execute %i log statements in total.\n", (int)total];
	[str appendFormat:@"%04.1f%% will be above log level threshold and will be filtered out.\n", verbose];
	[str appendFormat:@"%04.1f%% will execute Asynchronously.\n", (info + warn)];
	[str appendFormat:@"%04.1f%% will execute Synchronously.\n", error];
	[str appendString:@"\n"];
	[str appendFormat:@"BaseNSLogging :[%.4f][%.4f][%.4f]\n", base[4][0], base[4][1], base[4][2]];
	[str appendFormat:@"StaticLogging :[%.4f][%.4f][%.4f]\n", fmwk[sn][0][4][0], fmwk[sn][0][4][1], fmwk[sn][0][4][2]];
	[str appendFormat:@"DynamicLogging:[%.4f][%.4f][%.4f]\n", fmwk[sn][1][4][0], fmwk[sn][1][4][1], fmwk[sn][1][4][2]];
	[str appendString:@"\n\n\n"];
	
	return str;
}

+ (NSString *)csvResults
{
	NSMutableString *str = [NSMutableString stringWithCapacity:1000];
	
	// What are we trying to do here?
	// 
	// What we ultimately want is to compare the performance of the framework against the baseline.
	// This means we want to see the performance of the baseline for test 1,
	// and then right next to it we want to see the performance of the framework with each various configuration.
	// 
	// So we want it to kinda look like this for Test 1:
	// 
	// Base, [min], [avg], [max]
	// Suite 1 - Static, [min], [avg], [max]
	// Suite 1 - Dynamic, [min], [avg], [max]
	// Suite 2 - Static, [min], [avg], [max]
	// Suite 2 - Dynamic, [min], [avg], [max]
	// Suite 3 - Static, [min], [avg], [max]
	// Suite 3 - Dynamic, [min], [avg], [max]
	// 
	// This will import into Excel just fine.
	// However, I couldn't get Excel to make a decent looking graph with the data.
	// Perhaps I'm just not familiar enough with Excel.
	// But I was able to download OmniGraphSketcher,
	// and figure out how to create an awesome looking graph in less than 15 minutes.
	// And thus OmniGraphSketcher wins for me.
	// The only catch is that it wants to import the data with numbers instead of names.
	// So I need to convert the output to look like this:
	// 
	// 0, [min], [avg], [max]
	// 1, [min], [avg], [max]
	// 2, [min], [avg], [max]
	// 3, [min], [avg], [max]
	// 4, [min], [avg], [max]
	// 5, [min], [avg], [max]
	// 6, [min], [avg], [max]
	// 
	// I can then import the data into OmniGraphSketcher, and rename the X-axis points.
	
	// static NSTimeInterval base[5][3]; // [test][min,avg,max]
	// 
	// static NSTimeInterval fmwk[3][2][5][3]; // [suite][file][test][min,avg,max]
	
	int row = 0;
	int suite, file, test;
	
	for (test = 0; test < 5; test++)
	{
		[str appendFormat:@"%i, %.4f, %.4f, %.4f\n", row++, base[test][0], base[test][1], base[test][2]];
		
		for (suite = 0; suite < 3; suite++)
		{
			for (file = 0; file < 2; file++)
			{
				[str appendFormat:@"%i, %.4f, %.4f, %.4f\n", row++,
				       fmwk[suite][file][test][0], fmwk[suite][file][test][1], fmwk[suite][file][test][2]];
			}
		}
		
		row += 3;
	}
	
	return str;
}

+ (void)startPerformanceTests
{
	BOOL runBase   = YES;
	BOOL runSuite1 = YES;
	BOOL runSuite2 = YES;
	BOOL runSuite3 = YES;
	
	if (!runBase && !runSuite1 && !runSuite2 && !runSuite3)
	{
		// Nothing to do, all suites disabled
		return;
	}
	
	NSLog(@"Preparing to start performance tests...");
	NSLog(@"The results will be printed nicely when all logging has completed.\n\n");
	
	[NSThread sleepForTimeInterval:3.0];
	
	if (runBase)
	{
		[self executeTestsWithBase:YES framework:NO frameworkSuite:0];
	}
	
	NSString *printableResults1 = nil;
	NSString *printableResults2 = nil;
	NSString *printableResults3 = nil;
	
	if (runSuite1)
	{
		[self configureLoggingForSuite1];
		[self executeTestsWithBase:NO framework:YES frameworkSuite:1];
		
		printableResults1 = [self printableResultsForSuite:1];
		
		NSLog(@"\n\n\n\n");
	}
	if (runSuite2)
	{
		[self configureLoggingForSuite2];
		[self executeTestsWithBase:NO framework:YES frameworkSuite:2];
		
		printableResults2 = [self printableResultsForSuite:2];
		
		NSLog(@"\n\n\n\n");
	}
	if (runSuite3)
	{
		[self configureLoggingForSuite3];
		[self executeTestsWithBase:NO framework:YES frameworkSuite:3];
		
		printableResults3 = [self printableResultsForSuite:3];
		
		NSLog(@"\n\n\n\n");
	}
	
	if (runSuite1)
	{
		NSLog(@"======================================================================");
		NSLog(@"Benchmark Suite 1:");
		NSLog(@"Logging framework configured to log to console only.");
		NSLog(@"\n\n%@", printableResults1);
		NSLog(@"======================================================================");
	}
	if (runSuite2)
	{
		NSLog(@"======================================================================");
		NSLog(@"Benchmark Suite 2:");
		NSLog(@"Logging framework configured to log to file only.");
		NSLog(@"\n\n%@", printableResults2);
		NSLog(@"======================================================================");
	}
	if (runSuite3)
	{
		NSLog(@"======================================================================");
		NSLog(@"Benchmark Suite 3:");
		NSLog(@"Logging framework configured to log to console & file.");
		NSLog(@"\n\n%@", printableResults3);
		NSLog(@"======================================================================");
	}
	
#if TARGET_OS_IPHONE
	NSString *csvResultsPath = [@"~/Documents/LumberjackBenchmark.csv" stringByExpandingTildeInPath];
#else
	NSString *csvResultsPath = [@"~/Desktop/LumberjackBenchmark.csv" stringByExpandingTildeInPath];
#endif
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:csvResultsPath])
	{
		[[NSFileManager defaultManager] createFileAtPath:csvResultsPath contents:nil attributes:nil];
	}
	
	NSFileHandle *csvResultsFile = [NSFileHandle fileHandleForWritingAtPath:csvResultsPath];
	
	NSString *csvRsults = [self csvResults];
	[csvResultsFile writeData:[csvRsults dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSLog(@"CSV results file written to:\n%@", csvResultsPath);
}

@end

//
//  PerformanceTesting.h
//  Benchmarking
//
//  CocoaLumberjack Demos
//

#import <Foundation/Foundation.h>

#define SPEED_TEST_0_COUNT 1000 // Total log statements
#define SPEED_TEST_1_COUNT 1000 // Total log statements
#define SPEED_TEST_2_COUNT 1000 // Total log statements
#define SPEED_TEST_3_COUNT  250 // Per log level (multiply by 4 to get total)

#define SPEED_TEST_4_VERBOSE_COUNT 900
#define SPEED_TEST_4_INFO_COUNT    000
#define SPEED_TEST_4_WARN_COUNT    000
#define SPEED_TEST_4_ERROR_COUNT   100

// Further documentation on these tests may be found in the implementation file.

@interface PerformanceTesting : NSObject

+ (void)startPerformanceTests;

@end

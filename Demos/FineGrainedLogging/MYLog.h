#import <CocoaLumberjack/CocoaLumberjack.h>

// The first 4 bits are being used by the standard levels (0 - 3) 
// All other bits are fair game for us to use.

#define LOG_FLAG_FOOD_TIMER  (1 << 5) // 0...0100000
#define LOG_FLAG_SLEEP_TIMER (1 << 6) // 0...1000000

#define DDLogFoodTimer(frmt, ...)  LOG_MAYBE(YES, ddLogLevel, LOG_FLAG_FOOD_TIMER,  0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogSleepTimer(frmt, ...) LOG_MAYBE(YES, ddLogLevel, LOG_FLAG_SLEEP_TIMER, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

// Now we decide which flags we want to enable in our application

#define LOG_FLAG_TIMERS (LOG_FLAG_FOOD_TIMER | LOG_FLAG_SLEEP_TIMER)

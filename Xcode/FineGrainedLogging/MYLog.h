#import "DDLog.h"

// The first 4 bits are being used by the standard levels (0 - 3) 
// All other bits are fair game for us to use.

#define LOG_FLAG_FOOD_TIMER    (1 << 4)  // 0...0010000
#define LOG_FLAG_SLEEP_TIMER   (1 << 5)  // 0...0100000

#define LOG_FOOD_TIMER  (ddLogLevel & LOG_FLAG_FOOD_TIMER)
#define LOG_SLEEP_TIMER (ddLogLevel & LOG_FLAG_SLEEP_TIMER)

#define DDLogFoodTimer(frmt, ...)   ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_FOOD_TIMER,  frmt, ##__VA_ARGS__)
#define DDLogSleepTimer(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_SLEEP_TIMER, frmt, ##__VA_ARGS__)

// Now we decide which flags we want to enable in our application

#define LOG_FLAG_TIMERS (LOG_FLAG_FOOD_TIMER | LOG_FLAG_SLEEP_TIMER)

#import <Foundation/Foundation.h>
#import "DDLog.h"


/**
 * Welcome to Cocoa Lumberjack!
 * 
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 * 
 * If you're new to the project you may wish to read the "Getting Started" page.
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/GettingStarted
 * 
 * 
 * This class provides a log formatter that prints the dispatch_queue label instead of the mach_thread_id.
 * 
 * A log formatter can be added to any logger to format and/or filter its output.
 * You can learn more about log formatters here:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomFormatters
 * 
 * A typical NSLog (or DDTTYLogger) prints detailed info as [<process_id>:<thread_id>].
 * For example:
 * 
 * 2011-10-17 20:21:45.435 AppName[19928:5207] Your log message here
 * 
 * Where:
 * - 19928 = process id
 * -  5207 = thread id (mach_thread_id printed in hex)
 * 
 * When using grand central dispatch (GCD), this information is less useful.
 * This is because a single serial dispatch queue may be run on any thread from an internally managed thread pool.
 * For example:
 * 
 * 2011-10-17 20:32:31.111 AppName[19954:4d07] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.112 AppName[19954:5207] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.113 AppName[19954:2c55] Message from my_serial_dispatch_queue
 * 
 * This formatter allows you to replace the standard detail info with the dispatch_queue name.
 * For example:
 * 
 * 2011-10-17 20:32:31.111 AppName[img-scaling] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.112 AppName[img-scaling] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.113 AppName[img-scaling] Message from my_serial_dispatch_queue
**/
@interface DispatchQueueLogFormatter : NSObject <DDLogFormatter>

/**
 * Standard init method.
 * 
 * @see queueLength
 * @see rightAlign
**/
- (id)init;

/**
 * The queueLength is simply the number of characters that will be inside the [detail box].
 * For example:
 * 
 * Say a dispatch_queue has a label of "diskIO".
 * If the queueLength is 4: [disk]
 * If the queueLength is 5: [diskI]
 * If the queueLength is 6: [diskIO]
 * If the queueLength is 7: [diskIO ]
 * If the queueLength is 8: [diskIO  ]
 * 
 * The default queueLength is 6.
 * 
 * The output will also be influenced by the rightAlign property.
**/
@property (assign) int queueLength;

/**
 * The rightAlign property allows you to specify whether the detail info should be
 * left or right aligned within the [detail box].
 * 
 * For example:
 * Say a dispatch_queue has a label of "diskIO".
 * 
 * If leftAlign and queueLength is 4: [disk]
 * If leftAlign and queueLength is 5: [diskI]
 * If leftAlign and queueLength is 6: [diskIO]
 * If leftAlign and queueLength is 7: [diskIO ]
 * If leftAlign and queueLength is 8: [diskIO  ]
 * 
 * If rightAlign and queueLength is 4: [skIO]
 * If rightAlign and queueLength is 5: [iskIO]
 * If rightAlign and queueLength is 6: [diskIO]
 * If rightAlign and queueLength is 7: [ diskIO]
 * If rightAlign and queueLength is 8: [  diskIO]
 * 
 * The default is leftAlignment.
**/
@property (assign) BOOL rightAlign;

/**
 * Sometimes queue labels have long names like "com.apple.main-queue",
 * but you'd prefer something shorter like simply "main".
 * 
 * This method allows you to set such preferred replacements.
 * The above example is set by default.
 * 
 * To remove/undo a previous replacement, invoke this method with nil for the 'shortLabel' parameter.
**/
- (NSString *)replacementStringForQueueLabel:(NSString *)longLabel;
- (void)setReplacementString:(NSString *)shortLabel forQueueLabel:(NSString *)longLabel;

@end

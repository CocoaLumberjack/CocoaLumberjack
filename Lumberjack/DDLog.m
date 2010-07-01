#import "DDLog.h"

#import <pthread.h>
#import <objc/runtime.h>
#import <libkern/OSAtomic.h>

// We probably shouldn't be using DDLog() statements within the DDLog implementation.
// But we still want to leave our log statements for any future debugging,
// and to allow other developers to trace the implementation (which is a great learning tool).
// 
// So we use a primitive logging macro around NSLog.
// We maintain the NS prefix on the macros to be explicit about the fact that we're using NSLog.

#define DEBUG NO

#define NSLogDebug(frmt, ...) do{ if(DEBUG) NSLog((frmt), ##__VA_ARGS__); } while(0)

// Specifies the maximum queue size of the logging thread.
// 
// Since most logging is asynchronous, its possible for rogue threads to flood the logging queue.
// That is, to issue an abundance of log statements faster than the logging thread can keepup.
// Typically such a scenario occurs when log statements are added haphazardly within large loops,
// but may also be possible if relatively slow loggers are being used.
// 
// This property caps the queue size at a given number of outstanding log statements.
// If a thread attempts to issue a log statement when the queue is already maxed out,
// the issuing thread will block until the queue size drops below the max again.

#define LOG_MAX_QUEUE_SIZE 1000 // Should not exceed INT32_MAX

#if GCD_MAYBE_AVAILABLE
struct LoggerNode {
	id <DDLogger> logger;
	dispatch_queue_t loggerQueue;
    struct LoggerNode * next;
};
typedef struct LoggerNode LoggerNode;
#endif


@interface DDLog (PrivateAPI)

+ (void)lt_addLogger:(id <DDLogger>)logger;
+ (void)lt_removeLogger:(id <DDLogger>)logger;
+ (void)lt_removeAllLoggers;
+ (void)lt_log:(DDLogMessage *)logMessage;
+ (void)lt_flush;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLog

#if GCD_MAYBE_AVAILABLE

  // All logging statements are added to the same queue to ensure FIFO operation.
  static dispatch_queue_t loggingQueue;

  // Individual loggers are executed concurrently per log statement.
  // Each logger has it's own associated queue, and a dispatch group is used for synchrnoization.
  static dispatch_group_t loggingGroup;

  // A linked list is used to manage all the individual loggers.
  // Each item in the linked list also includes the loggers associated dispatch queue.
  static LoggerNode *loggerNodes;

  // In order to prevent to queue from growing infinitely large,
  // a maximum size is enforced (LOG_MAX_QUEUE_SIZE).
  static dispatch_semaphore_t queueSemaphore;

#endif

#if GCD_MAYBE_UNAVAILABLE

  // All logging statements are queued onto the same thread to ensure FIFO operation.
  static NSThread *loggingThread;

  // An array is used to manage all the individual loggers.
  // The array is only modified on the loggingThread.
  static NSMutableArray *loggers;

  // In order to prevent to queue from growing infinitely large,
  // a maximum size is enforced (LOG_MAX_QUEUE_SIZE).
  static int32_t queueSize;               // Incremented and decremented locklessly using OSAtomic operations
  static NSCondition *condition;          // Not used unless the queueSize exceeds its max
  static NSMutableArray *blockedThreads;  // Not used unless the queueSize exceeds its max

#endif

/**
 * The runtime sends initialize to each class in a program exactly one time just before the class,
 * or any class that inherits from it, is sent its first message from within the program. (Thus the
 * method may never be invoked if the class is not used.) The runtime sends the initialize message to
 * classes in a thread-safe manner. Superclasses receive this message before their subclasses.
 *
 * This method may also be called directly (assumably by accident), hence the safety mechanism.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		initialized = YES;
		
		if (IS_GCD_AVAILABLE)
		{
		#if GCD_MAYBE_AVAILABLE
			
			NSLogDebug(@"DDLog: Using grand central dispatch");
			
			loggingQueue = dispatch_queue_create("cocoa.lumberjack", NULL);
			loggingGroup = dispatch_group_create();
			
			loggerNodes = NULL;
			
			queueSemaphore = dispatch_semaphore_create(LOG_MAX_QUEUE_SIZE);
			
		#endif
		}
		else
		{
		#if GCD_MAYBE_UNAVAILABLE
			
			NSLogDebug(@"DDLog: GCD not available");
			
			loggingThread = [[NSThread alloc] initWithTarget:self selector:@selector(lt_main:) object:nil];
			[loggingThread start];
			
			loggers = [[NSMutableArray alloc] initWithCapacity:4];
			
			queueSize = 0;
			
			condition = [[NSCondition alloc] init];
			blockedThreads = [[NSMutableArray alloc] init];
			
		#endif
		}
		
	#if TARGET_OS_IPHONE
		NSString *notificationName = UIApplicationWillTerminateNotification;
	#else
		NSString *notificationName = NSApplicationWillTerminateNotification;
	#endif
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(applicationWillTerminate:)
		                                             name:notificationName
		                                           object:nil];
	}
}

#if GCD_MAYBE_AVAILABLE

/**
 * Provides access to the logging queue.
**/
+ (dispatch_queue_t)loggingQueue
{
	return loggingQueue;
}

#endif

#if GCD_MAYBE_UNAVAILABLE

/**
 * Provides access to the logging thread.
**/
+ (NSThread *)loggingThread
{
	return loggingThread;
}

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void)applicationWillTerminate:(NSNotification *)notification
{
	[self flushLog];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Logger Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void)addLogger:(id <DDLogger>)logger
{
	if (logger == nil) return;
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		dispatch_block_t addLoggerBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[self lt_addLogger:logger];
			
			[pool release];
		};
		
		dispatch_async(loggingQueue, addLoggerBlock);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		[self performSelector:@selector(lt_addLogger:) onThread:loggingThread withObject:logger waitUntilDone:NO];
		
	#endif
	}
}

+ (void)removeLogger:(id <DDLogger>)logger
{
	if (logger == nil) return;
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		dispatch_block_t removeLoggerBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[self lt_removeLogger:logger];
			
			[pool release];
		};
		
		dispatch_async(loggingQueue, removeLoggerBlock);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		[self performSelector:@selector(lt_removeLogger:) onThread:loggingThread withObject:logger waitUntilDone:NO];
		
	#endif
	}
}

+ (void)removeAllLoggers
{
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		dispatch_block_t removeAllLoggersBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[self lt_removeAllLoggers];
			
			[pool release];
		};
		
		dispatch_async(loggingQueue, removeAllLoggersBlock);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		[self performSelector:@selector(lt_removeAllLoggers) onThread:loggingThread withObject:nil waitUntilDone:NO];
		
	#endif
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Master Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void)queueLogMessage:(DDLogMessage *)logMessage synchronously:(BOOL)flag
{
	// We have a tricky situation here...
	// 
	// In the common case, when the queueSize is below the maximumQueueSize,
	// we want to simply enqueue the logMessage. And we want to do this as fast as possible,
	// which means we don't want to block and we don't want to use any locks.
	// 
	// However, if the queueSize gets too big, we want to block.
	// But we have very strict requirements as to when we block, and how long we block.
	// 
	// The following example should help illustrate our requirements:
	// 
	// Imagine that the maximum queue size is configured to be 5,
	// and that there are already 5 log messages queued.
	// Let us call these 5 queued log messages A, B, C, D, and E. (A is next to be executed)
	// 
	// Now if our thread issues a log statement (let us call the log message F),
	// it should block before the message is added to the queue.
	// Furthermore, it should be unblocked immediately after A has been unqueued.
	// 
	// The requirements are strict in this manner so that we block only as long as necessary,
	// and so that blocked threads are unblocked in the order in which they were blocked.
	// 
	// Returning to our previous example, let us assume that log messages A through E are still queued.
	// Our aforementioned thread is blocked attempting to queue log message F.
	// Now assume we have another separate thread that attempts to issue log message G.
	// It should block until log messages A and B have been unqueued.
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		// We are using a counting semaphore provided by GCD.
		// The semaphore is initialized with our LOG_MAX_QUEUE_SIZE value.
		// Everytime we want to queue a log message we decrement this value.
		// If the resulting value is less than zero,
		// the semaphore function waits in FIFO order for a signal to occur before returning.
		// 
		// A dispatch semaphore is an efficient implementation of a traditional counting semaphore.
		// Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked.
		// If the calling semaphore does not need to block, no kernel call is made.
		
		dispatch_semaphore_wait(queueSemaphore, DISPATCH_TIME_FOREVER);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		// We're going increment our queue size (in an atomic fashion).
		// If the queue size would exceed our LOG_MAX_QUEUE_SIZE value,
		// then we're going to take a lock, and add ourself to the blocked threads array.
		// Then we wait for the logging thread to signal us.
		// When it does, we automatically reaquire the lock,
		// and check to see if we have been removed from the blocked threads array.
		// When this occurs we are unblocked, and we can go ahead and queue our log message.
		
		int32_t newQueueSize = OSAtomicIncrement32(&queueSize);
		if (newQueueSize > LOG_MAX_QUEUE_SIZE)
		{
			NSLogDebug(@"DDLog: Blocking thread %@ (newQueueSize=%i)", [logMessage threadID], newQueueSize);
			
			[condition lock];
			
			NSString *currentThreadID = [logMessage threadID];
			[blockedThreads addObject:currentThreadID];
			
			NSUInteger lastKnownIndex = [blockedThreads count] - 1;
			
			if (lastKnownIndex == 0)
			{
				NSLogDebug(@"DDLog: Potential edge case: First blocked thread -> Signaling condition...");
				
				// Edge case:
				// The loggingThread/loggingQueue acquired the lock before we did,
				// but it immediately discovered the blockedThreads array was empty.
				
				[condition signal];
			}
			
			BOOL done = NO;
			while (!done)
			{
				BOOL found = NO;
				NSUInteger i;
				NSUInteger count = [blockedThreads count];
				
				for (i = 0; i <= lastKnownIndex && i < count && !found; i++)
				{
					NSString *blockedThreadID = [blockedThreads objectAtIndex:i];
					
					// Instead of doing a string comparison,
					// we can save CPU cycles by doing an pointer comparison,
					// since we still have access to the string that we added the array.
					
					if (blockedThreadID == currentThreadID)
					{
						found = YES;
						lastKnownIndex = i;
					}
				}
				
				// If our currentThreadID is still in the blockedThreads array,
				// then we are still blocked, and we're not done.
				
				done = !found;
				
				if (!done)
				{
					[condition wait];
				}
			}
			
			
			[condition unlock];
			
			NSLogDebug(@"DDLog: Unblocking thread %@", [logMessage threadID]);
		}
		
	#endif
	}
	
	// We've now sure we won't overflow the queue.
	// It is time to queue our log message.
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		dispatch_block_t logBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[self lt_log:logMessage];
			
			[pool release];
		};
		
		if (flag)
			dispatch_sync(loggingQueue, logBlock);
		else
			dispatch_async(loggingQueue, logBlock);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		[self performSelector:@selector(lt_log:) onThread:loggingThread withObject:logMessage waitUntilDone:flag];
		
	#endif
	}
}

+ (void)log:(BOOL)synchronous
      level:(int)level
       flag:(int)flag
       file:(const char *)file
   function:(const char *)function
       line:(int)line
     format:(NSString *)format, ...
{
	va_list args;
	if (format)
	{
		va_start(args, format);
		
		NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
		DDLogMessage *logMessage = [[DDLogMessage alloc] initWithLogMsg:logMsg
		                                                          level:level
		                                                           flag:flag
		                                                           file:file
		                                                       function:function
		                                                           line:line];
		
		[self queueLogMessage:logMessage synchronously:synchronous];
		
		[logMessage release];
		[logMsg release];
		
		va_end(args);
	}
}

+ (void)flushLog
{
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		dispatch_block_t flushBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[self lt_flush];
			
			[pool release];
		};
		
		dispatch_sync(loggingQueue, flushBlock);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		[self performSelector:@selector(lt_flush) onThread:loggingThread withObject:nil waitUntilDone:YES];
		
	#endif
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Registered Dynamic Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)isRegisteredClass:(Class)class
{
	Protocol *NSObjectProtocol = @protocol(NSObject);
	
	// Not all classes are guaranteed to inherit from NSObject.
	// If they do not, then we cannot invoke the respondsToSelector method.
	
	if (class_conformsToProtocol(class, NSObjectProtocol))
	{
		// It sure would be nice if we could use class_respondsToSelector().
		// However, this tests if instances of the class respond to the selector.
		// The methods we're testing for are class methods.
		
		SEL selector1 = @selector(ddLogLevel);
		SEL selector2 = @selector(ddSetLogLevel:);
		
		if ([class respondsToSelector:selector1] && [class respondsToSelector:selector2])
		{
			return YES;
		}
	}
	
	return NO;
}

+ (NSArray *)registeredClasses
{
	int numClasses;
	
	// We're going to get the list of all registered classes.
	// The Objective-C runtime library automatically registers all the classes defined in your source code.
	// 
	// To do this we use the following method (documented in the Objective-C Runtime Reference):
	// 
	// int objc_getClassList(Class *buffer, int bufferLen)
	// 
	// We can pass (NULL, 0) to obtain the total number of
	// registered class definitions without actually retrieving any class definitions.
	// This allows us to allocate the minimum amount of memory needed for the application.
	
	numClasses = objc_getClassList(NULL, 0);
	
	// The numClasses method now tells us how many classes we have.
	// So we can allocate our buffer, and get pointers to all the class definitions.
	
	Class *classes = malloc(sizeof(Class) * numClasses);
	
	numClasses = objc_getClassList(classes, numClasses);
	
	// We can now loop through the classes, and test each one to see if it is a DDLogging class.
	
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:numClasses];
	
	for (int i = 0; i < numClasses; i++)
	{
		Class class = classes[i];
		
		if ([self isRegisteredClass:class])
		{
			[result addObject:class];
		}
	}
	
	free(classes);
	
	return result;
}

+ (NSArray *)registeredClassNames
{
	NSArray *registeredClasses = [self registeredClasses];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[registeredClasses count]];
	
	for (Class class in registeredClasses)
	{
		[result addObject:NSStringFromClass(class)];
	}
	
	return result;
}

+ (int)logLevelForClass:(Class)aClass
{
	if ([self isRegisteredClass:aClass])
	{
		return [aClass ddLogLevel];
	}
	
	return -1;
}

+ (int)logLevelForClassWithName:(NSString *)aClassName
{
	Class aClass = NSClassFromString(aClassName);
	
	return [self logLevelForClass:aClass];
}

+ (void)setLogLevel:(int)logLevel forClass:(Class)aClass
{
	if ([self isRegisteredClass:aClass])
	{
		[aClass ddSetLogLevel:logLevel];
	}
}

+ (void)setLogLevel:(int)logLevel forClassWithName:(NSString *)aClassName
{
	Class aClass = NSClassFromString(aClassName);
	
	[self setLogLevel:logLevel forClass:aClass];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Logging Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if GCD_MAYBE_UNAVAILABLE

/**
 * Entry point for logging thread.
**/
+ (void)lt_main:(id)ignore
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// We can't run the run loop unless it has an associated input source or a timer.
	// So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
	[NSTimer scheduledTimerWithTimeInterval:DBL_MAX target:self selector:@selector(ignore:) userInfo:nil repeats:NO];
	
	[[NSRunLoop currentRunLoop] run];
	
	[pool release];
}

#endif

/**
 * This method should only be run on the logging thread/queue.
**/
+ (void)lt_addLogger:(id <DDLogger>)logger
{
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		// Add to linked list of LoggerNode elements.
		// Need to create loggerQueue if loggerNode doesn't provide one.
		
		LoggerNode *loggerNode = malloc(sizeof(LoggerNode));
		loggerNode->logger = [logger retain];
		
		const char *loggerQueueName = NULL;
		if ([logger respondsToSelector:@selector(loggerName)])
		{
			loggerQueueName = [[logger loggerName] UTF8String];
		}
		
		loggerNode->loggerQueue = dispatch_queue_create(loggerQueueName, NULL);
		
		loggerNode->next = loggerNodes;
		loggerNodes = loggerNode;
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		// Add to loggers array
		
		[loggers addObject:logger];
		
	#endif
	}
	
	if ([logger respondsToSelector:@selector(didAddLogger)])
	{
		[logger didAddLogger];
	}
}

/**
 * This method should only be run on the logging thread/queue.
**/
+ (void)lt_removeLogger:(id <DDLogger>)logger
{
	if ([logger respondsToSelector:@selector(willRemoveLogger)])
	{
		[logger willRemoveLogger];
	}
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		// Remove from linked list of LoggerNode elements.
		// 
		// Need to release:
		// - logger
		// - loggerQueue
		// - loggerNode
		
		LoggerNode *prevNode = NULL;
		LoggerNode *currentNode = loggerNodes;
		
		while (currentNode)
		{
			if (currentNode->logger == logger)
			{
				if (prevNode)
				{
					// LoggerNode had previous node pointing to it.
					prevNode->next = currentNode->next;
				}
				else
				{
					// LoggerNode was first in list. Update loggerNodes pointer.
					loggerNodes = currentNode->next;
				}
				
				[currentNode->logger release];
				currentNode->logger = nil;
				
				dispatch_release(currentNode->loggerQueue);
				currentNode->loggerQueue = NULL;
				
				currentNode->next = NULL;
				
				free(currentNode);
				
				break;
			}
			
			prevNode = currentNode;
			currentNode = currentNode->next;
		}
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
	
		// Remove from loggers array
		
		[loggers removeObject:logger];
		
	#endif
	}
}

/**
 * This method should only be run on the logging thread/queue.
**/
+ (void)lt_removeAllLoggers
{
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		// Iterate through linked list of LoggerNode elements.
		// For each one, notify the logger, and deallocate all associated resources.
		// 
		// Need to release:
		// - logger
		// - loggerQueue
		// - loggerNode
		
		LoggerNode *nextNode;
		LoggerNode *currentNode = loggerNodes;
		
		while (currentNode)
		{
			if ([currentNode->logger respondsToSelector:@selector(willRemoveLogger)])
			{
				[currentNode->logger willRemoveLogger];
			}
			
			nextNode = currentNode->next;
			
			[currentNode->logger release];
			currentNode->logger = nil;
			
			dispatch_release(currentNode->loggerQueue);
			currentNode->loggerQueue = NULL;
			
			currentNode->next = NULL;
			
			free(currentNode);
			
			currentNode = nextNode;
		}
		
		loggerNodes = NULL;
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		// Notify all loggers.
		// And then remove them all from loggers array.
		
		for (id <DDLogger> logger in loggers)
		{
			if ([logger respondsToSelector:@selector(willRemoveLogger)])
			{
				[logger willRemoveLogger];
			}
		}
		
		[loggers removeAllObjects];
		
	#endif
	}
}

/**
 * This method should only be run on the logging thread/queue.
**/
+ (void)lt_log:(DDLogMessage *)logMessage
{
	// Execute the given log message on each of our loggers.
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		// Execute each logger concurrently, each within its own queue.
		// All blocks are added to same group.
		// After each block has been queued, wait on group.
		// 
		// The waiting ensures that a slow logger doesn't end up with a large queue of pending log messages.
		// This would defeat the purpose of the efforts we made earlier to restrict the max queue size.
		
		LoggerNode *currentNode = loggerNodes;
		
		while (currentNode)
		{
			dispatch_block_t loggerBlock = ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[currentNode->logger logMessage:logMessage];
				
				[pool release];
			};
			
			dispatch_group_async(loggingGroup, currentNode->loggerQueue, loggerBlock);
			
			currentNode = currentNode->next;
		}
		
		dispatch_group_wait(loggingGroup, DISPATCH_TIME_FOREVER);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		for (id <DDLogger> logger in loggers)
		{
			[logger logMessage:logMessage];
		}
		
	#endif
	}
	
	// If our queue got too big, there may be blocked threads waiting to add log messages to the queue.
	// Since we've now dequeued an item from the log, we may need to unblock the next thread.
	
	if (IS_GCD_AVAILABLE)
	{
	#if GCD_MAYBE_AVAILABLE
		
		// We are using a counting semaphore provided by GCD.
		// The semaphore is initialized with our LOG_MAX_QUEUE_SIZE value.
		// When a log message is queued this value is decremented.
		// When a log message is dequeued this value is incremented.
		// If the value ever drops below zero,
		// the queueing thread blocks and waits in FIFO order for us to signal it.
		// 
		// A dispatch semaphore is an efficient implementation of a traditional counting semaphore.
		// Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked.
		// If the calling semaphore does not need to block, no kernel call is made.
		
		dispatch_semaphore_signal(queueSemaphore);
		
	#endif
	}
	else
	{
	#if GCD_MAYBE_UNAVAILABLE
		
		int32_t newQueueSize = OSAtomicDecrement32(&queueSize);
		if (newQueueSize >= LOG_MAX_QUEUE_SIZE)
		{
			// There is an existing blocked thread waiting for us.
			// When the thread went to queue a log message, it first incremented the queueSize.
			// At this point it realized that was going to exceed the maxQueueSize.
			// It then added itself to the blockedThreads list, and is now waiting for us to signal it.
			
			[condition lock];
			
			while ([blockedThreads count] == 0)
			{
				NSLogDebug(@"DDLog: Edge case: Empty blocked threads array -> Waiting for condition...");
				
				// Edge case.
				// We acquired the lock before the blockedThread did.
				// That is why the array is empty.
				// Allow it to acquire the lock and signal us.
				
				[condition wait];
			}
			
			// The blockedThreads variable is acting as a queue. (FIFO)
			// Whatever was the first thread to block can now be unblocked.
			// This means that thread will block only until the count of
			// prevoiusly queued plus previously reserved log messages before it have dropped below the maxQueueSize.
			
			NSLogDebug(@"DDLog: Signaling thread %@ (newQueueSize=%i)", [blockedThreads objectAtIndex:0], newQueueSize);
			
			[blockedThreads removeObjectAtIndex:0];
			[condition broadcast];
			
			[condition unlock];
		}
		
	#endif
	}
}

/**
 * This method should only be run on the background logging thread.
**/
+ (void)lt_flush
{
	// All log statements issued before the flush method was invoked have now been flushed
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

NSString *ExtractFileNameWithoutExtension(const char *filePath, BOOL copy)
{
	if (filePath == NULL) return nil;
	
	char *lastSlash = NULL;
	char *lastDot = NULL;
	
	char *p = (char *)filePath;
	
	while (*p != '\0')
	{
		if (*p == '/')
			lastSlash = p;
		else if (*p == '.')
			lastDot = p;
		
		p++;
	}
	
	char *subStr;
	NSUInteger subLen;
	
	if (lastSlash)
	{
		if (lastDot)
		{
			// lastSlash -> lastDot
			subStr = lastSlash + 1;
			subLen = lastDot - subStr;
		}
		else
		{
			// lastSlash -> endOfString
			subStr = lastSlash + 1;
			subLen = p - subStr;
		}
	}
	else
	{
		if (lastDot)
		{
			// startOfString -> lastDot
			subStr = (char *)filePath;
			subLen = lastDot - subStr;
		}
		else
		{
			// startOfString -> endOfString
			subStr = (char *)filePath;
			subLen = p - subStr;
		}
	}
	
	if (copy)
	{
		return [[[NSString alloc] initWithBytes:subStr
		                                 length:subLen
		                               encoding:NSUTF8StringEncoding] autorelease];
	}
	else
	{
		// We can take advantage of the fact that __FILE__ is a string literal.
		// Specifically, we don't need to waste time copying the string.
		// We can just tell NSString to point to a range within the string literal.
		
		return [[[NSString alloc] initWithBytesNoCopy:subStr
		                                       length:subLen
		                                     encoding:NSUTF8StringEncoding
		                                 freeWhenDone:NO] autorelease];
	}
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLogMessage

- (id)initWithLogMsg:(NSString *)msg
               level:(int)level
                flag:(int)flag
                file:(const char *)aFile
            function:(const char *)aFunction
                line:(int)line
{
	if((self = [super init]))
	{
		logMsg = [msg retain];
		logLevel = level;
		logFlag = flag;
		file = aFile;
		function = aFunction;
		lineNumber = line;
		
		timestamp = [[NSDate alloc] init];
		
		machThreadID = pthread_mach_thread_np(pthread_self());
	}
	return self;
}

- (NSString *)threadID
{
	if (threadID == nil)
	{
		threadID = [[NSString alloc] initWithFormat:@"%x", machThreadID];
	}
	
	return threadID;
}

- (NSString *)fileName
{
	if (fileName == nil)
	{
		fileName = [ExtractFileNameWithoutExtension(file, NO) retain];
	}
	
	return fileName;
}

- (NSString *)methodName
{
	if (methodName == nil && function != NULL)
	{
		methodName = [[NSString alloc] initWithUTF8String:function];
	}
	
	return methodName;
}

- (void)dealloc
{
	[logMsg release];
	[timestamp release];
	
	[threadID release];
	[methodName release];
	
	[super dealloc];
}

@end

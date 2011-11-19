#import "DispatchQueueLogFormatter.h"
#import <libkern/OSAtomic.h>

/**
 * Welcome to Cocoa Lumberjack!
 * 
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 * 
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/GettingStarted
**/

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


@implementation DispatchQueueLogFormatter
{
	OSSpinLock lock;
	NSDateFormatter *dateFormatter;
	
	NSUInteger _minQueueLength;           // _prefix == Only access via atomic property
	NSUInteger _maxQueueLength;           // _prefix == Only access via atomic property
	NSMutableDictionary *_replacements;   // _prefix == Only access from within spinlock
}

- (id)init
{
	if ((self = [super init]))
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
		
		_minQueueLength = 0;
		_maxQueueLength = 0;
		_replacements = [[NSMutableDictionary alloc] init];
		
		// Set default replacements:
		
		[_replacements setObject:@"main" forKey:@"com.apple.main-thread"];
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize minQueueLength = _minQueueLength;
@synthesize maxQueueLength = _maxQueueLength;

- (NSString *)replacementStringForQueueLabel:(NSString *)longLabel
{
	NSString *result = nil;
	
	OSSpinLockLock(&lock);
	{
		result = [_replacements objectForKey:longLabel];
	}
	OSSpinLockUnlock(&lock);
	
	return result;
}

- (void)setReplacementString:(NSString *)shortLabel forQueueLabel:(NSString *)longLabel
{
	OSSpinLockLock(&lock);
	{
		if (shortLabel)
			[_replacements setObject:shortLabel forKey:longLabel];
		else
			[_replacements removeObjectForKey:longLabel];
	}
	OSSpinLockUnlock(&lock);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogFormatter
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	// As per the DDLogFormatter contract, this method is always invoked on the same thread/dispatch_queue
	
	NSString *timestamp = [dateFormatter stringFromDate:(logMessage->timestamp)];
	
	NSUInteger minQueueLength = self.minQueueLength;
	NSUInteger maxQueueLength = self.maxQueueLength;
	
	// Get the name of the queue, thread, or machID (whichever we are to use).
	
	NSString *threadLabel = nil;
	
	BOOL useQueueLabel = YES;
	BOOL useThreadName = NO;
	
	if (logMessage->queueLabel)
	{
		// If you manually create a thread, it's dispatch_queue will have one of the thread names below.
		// Since all such threads have the same name, we'd prefer to use the threadName or the machThreadID.
		
		char *names[] = { "com.apple.root.low-overcommit-priority",
		                  "com.apple.root.default-overcommit-priority",
		                  "com.apple.root.high-overcommit-priority"     };
		
		int i;
		for (i = 0; i < sizeof(names); i++)
		{
			if (strcmp(logMessage->queueLabel, names[1]) == 0)
			{
				useQueueLabel = NO;
				useThreadName = [logMessage->threadName length] > 0;
				break;
			}
		}
	}
	else
	{
		useQueueLabel = NO;
		useThreadName = [logMessage->threadName length] > 0;
	}
	
	if (useQueueLabel || useThreadName)
	{
		NSString *fullLabel;
		NSString *abrvLabel;
		
		if (useQueueLabel)
			fullLabel = [NSString stringWithUTF8String:logMessage->queueLabel];
		else
			fullLabel = logMessage->threadName;
		
		OSSpinLockLock(&lock);
		{
			abrvLabel = [_replacements objectForKey:fullLabel];
		}
		OSSpinLockUnlock(&lock);
		
		if (abrvLabel)
			threadLabel = abrvLabel;
		else
			threadLabel = fullLabel;
	}
	else
	{
		threadLabel = [NSString stringWithFormat:@"%x", logMessage->machThreadID];
	}
	
	// Now use the thread label in the output
	
	NSUInteger labelLength = [threadLabel length];
	
	// labelLength > maxQueueLength : truncate
	// labelLength < minQueueLength : padding
	//                              : exact
	
	if ((maxQueueLength > 0) && (labelLength > maxQueueLength))
	{
		// Truncate
		
		NSString *subLabel = [threadLabel substringToIndex:maxQueueLength];
		
		return [NSString stringWithFormat:@"%@ [%@] %@", timestamp, subLabel, logMessage->logMsg];
	}
	else if (labelLength < minQueueLength)
	{
		// Padding
		
		NSUInteger numSpaces = minQueueLength - labelLength;
		
		char spaces[numSpaces + 1];
		memset(spaces, ' ', numSpaces);
		spaces[numSpaces] = '\0';
		
		return [NSString stringWithFormat:@"%@ [%@%s] %@", timestamp, threadLabel, spaces, logMessage->logMsg];
	}
	else
	{
		// Exact
		
		return [NSString stringWithFormat:@"%@ [%@] %@", timestamp, threadLabel, logMessage->logMsg];
	}
}

@end

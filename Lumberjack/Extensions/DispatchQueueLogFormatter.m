#import "DispatchQueueLogFormatter.h"

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

- (NSString *)queueThreadLabelForLogMessage:(DDLogMessage *)logMessage
{
	// As per the DDLogFormatter contract, this method is always invoked on the same thread/dispatch_queue
	
	NSUInteger minQueueLength = self.minQueueLength;
	NSUInteger maxQueueLength = self.maxQueueLength;
	
	// Get the name of the queue, thread, or machID (whichever we are to use).
	
	NSString *queueThreadLabel = nil;
	
	BOOL useQueueLabel = YES;
	BOOL useThreadName = NO;
	
	if (logMessage->queueLabel)
	{
		// If you manually create a thread, it's dispatch_queue will have one of the thread names below.
		// Since all such threads have the same name, we'd prefer to use the threadName or the machThreadID.
		
		char *names[] = { "com.apple.root.low-priority",
		                  "com.apple.root.default-priority",
		                  "com.apple.root.high-priority",
		                  "com.apple.root.low-overcommit-priority",
		                  "com.apple.root.default-overcommit-priority",
		                  "com.apple.root.high-overcommit-priority"     };
		
		int length = sizeof(names) / sizeof(char *);
		
		int i;
		for (i = 0; i < length; i++)
		{
			if (strcmp(logMessage->queueLabel, names[i]) == 0)
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
			queueThreadLabel = abrvLabel;
		else
			queueThreadLabel = fullLabel;
	}
	else
	{
		queueThreadLabel = [NSString stringWithFormat:@"%x", logMessage->machThreadID];
	}
	
	// Now use the thread label in the output
	
	NSUInteger labelLength = [queueThreadLabel length];
	
	// labelLength > maxQueueLength : truncate
	// labelLength < minQueueLength : padding
	//                              : exact
	
	if ((maxQueueLength > 0) && (labelLength > maxQueueLength))
	{
		// Truncate
		
		return [queueThreadLabel substringToIndex:maxQueueLength];
	}
	else if (labelLength < minQueueLength)
	{
		// Padding
		
		NSUInteger numSpaces = minQueueLength - labelLength;
		
		char spaces[numSpaces + 1];
		memset(spaces, ' ', numSpaces);
		spaces[numSpaces] = '\0';
		
		return [NSString stringWithFormat:@"%@%s", queueThreadLabel, spaces];
	}
	else
	{
		// Exact
		
		return queueThreadLabel;
	}
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	NSString *timestamp = [dateFormatter stringFromDate:(logMessage->timestamp)];
	NSString *queueThreadLabel = [self queueThreadLabelForLogMessage:logMessage];
	
	return [NSString stringWithFormat:@"%@ [%@] %@", timestamp, queueThreadLabel, logMessage->logMsg];
}

@end

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
#warning This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag.
#endif

#define DEFAULT_QUEUE_LENGTH  6
#define     MIN_QUEUE_LENGTH  4
#define     MAX_QUEUE_LENGTH 35


@implementation DispatchQueueLogFormatter
{
	OSSpinLock lock;
	NSDateFormatter *dateFormatter;
	
	int _queueLength;                     // _prefix == Only access from within spinlock
	BOOL _rightAlign;                     // _prefix == Only access from within spinlock
	NSMutableDictionary *_replacements;   // _prefix == Only access from within spinlock
}

- (id)init
{
	if ((self = [super init]))
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
		
		_queueLength = DEFAULT_QUEUE_LENGTH;
		_rightAlign = NO;
		_replacements = [[NSMutableDictionary alloc] init];
		
		// Set default replacements:
		
		[_replacements setObject:@"main" forKey:@"com.apple.main-thread"];
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (int)queueLength
{
	int result = 0;
	
	OSSpinLockLock(&lock);
	{
		result = _queueLength;
	}
	OSSpinLockUnlock(&lock);
	
	return result;
}

- (void)setQueueLength:(int)newQueueLength
{
	OSSpinLockLock(&lock);
	{
		if (newQueueLength > MAX_QUEUE_LENGTH) {
			_queueLength = MAX_QUEUE_LENGTH;
		}
		else if (newQueueLength < MIN_QUEUE_LENGTH) {
			_queueLength = MIN_QUEUE_LENGTH;
		}
		else {
			_queueLength = newQueueLength;
		}
	}
	OSSpinLockUnlock(&lock);
}

- (BOOL)rightAlign
{
	BOOL result = NO;
	
	OSSpinLockLock(&lock);
	{
		result = _rightAlign;
	}
	OSSpinLockUnlock(&lock);
	
	return result;
}

- (void)setRightAlign:(BOOL)newRightAlign
{
	OSSpinLockLock(&lock);
	{
		_rightAlign = newRightAlign;
	}
	OSSpinLockUnlock(&lock);
}

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
	
	int queueLength = 0;
	BOOL rightAlign = NO;
	
	NSString *timestamp = [dateFormatter stringFromDate:(logMessage->timestamp)];
	NSString *label;
	
	if (logMessage->queueLabel)
	{
		NSString *longLabel = [NSString stringWithUTF8String:logMessage->queueLabel];
		
		NSString *shortLabel = nil;
		
		OSSpinLockLock(&lock);
		{
			queueLength = _queueLength;
			rightAlign = _rightAlign;
			
			shortLabel = [_replacements objectForKey:longLabel];
		}
		OSSpinLockUnlock(&lock);
		
		if (shortLabel)
			label = shortLabel;
		else
			label = longLabel;
	}
	else
	{
		label = [NSString stringWithFormat:@"%x", logMessage->machThreadID];
		
		OSSpinLockLock(&lock);
		{
			queueLength = _queueLength;
			rightAlign = _rightAlign;
		}
		OSSpinLockUnlock(&lock);
	}
	
	
	int labelLength = (int)[label length];
	
	if (labelLength == queueLength)
	{
		return [NSString stringWithFormat:@"%@ [%@] %@", timestamp, label, logMessage->logMsg];
	}
	else if (labelLength > queueLength)
	{
		NSString *subLabel;
		if (rightAlign)
			subLabel = [label substringFromIndex:(labelLength - queueLength)];
		else
			subLabel = [label substringToIndex:queueLength];
		
		return [NSString stringWithFormat:@"%@ [%@] %@", timestamp, subLabel, logMessage->logMsg];
	}
	else
	{
		int numSpaces = queueLength - labelLength;
		
		char spaces[numSpaces + 1];
		memset(spaces, ' ', numSpaces);
		spaces[numSpaces] = '\0';
		
		if (rightAlign)
			return [NSString stringWithFormat:@"%@ [%s%@] %@", timestamp, spaces, label, logMessage->logMsg];
		else
			return [NSString stringWithFormat:@"%@ [%@%s] %@", timestamp, label, spaces, logMessage->logMsg];
	}
}

@end

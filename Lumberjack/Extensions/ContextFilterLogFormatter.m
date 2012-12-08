#import "ContextFilterLogFormatter.h"
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

@interface LoggingContextSet : NSObject

- (void)addToSet:(int)loggingContext;
- (void)removeFromSet:(int)loggingContext;

- (NSArray *)currentSet;

- (BOOL)isInSet:(int)loggingContext;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ContextWhitelistFilterLogFormatter
{
	LoggingContextSet *contextSet;
}

- (id)init
{
	if ((self = [super init]))
	{
		contextSet = [[LoggingContextSet alloc] init];
	}
	return self;
}


- (void)addToWhitelist:(int)loggingContext
{
	[contextSet addToSet:loggingContext];
}

- (void)removeFromWhitelist:(int)loggingContext
{
	[contextSet removeFromSet:loggingContext];
}

- (NSArray *)whitelist
{
	return [contextSet currentSet];
}

- (BOOL)isOnWhitelist:(int)loggingContext
{
	return [contextSet isInSet:loggingContext];
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	if ([self isOnWhitelist:logMessage->logContext])
		return logMessage->logMsg;
	else
		return nil;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ContextBlacklistFilterLogFormatter
{
	LoggingContextSet *contextSet;
}

- (id)init
{
	if ((self = [super init]))
	{
		contextSet = [[LoggingContextSet alloc] init];
	}
	return self;
}


- (void)addToBlacklist:(int)loggingContext
{
	[contextSet addToSet:loggingContext];
}

- (void)removeFromBlacklist:(int)loggingContext
{
	[contextSet removeFromSet:loggingContext];
}

- (NSArray *)blacklist
{
	return [contextSet currentSet];
}

- (BOOL)isOnBlacklist:(int)loggingContext
{
	return [contextSet isInSet:loggingContext];
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	if ([self isOnBlacklist:logMessage->logContext])
		return nil;
	else
		return logMessage->logMsg;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation LoggingContextSet
{
	OSSpinLock lock;
	NSMutableSet *set;
}

- (id)init
{
	if ((self = [super init]))
	{
		set = [[NSMutableSet alloc] init];
	}
	return self;
}


- (void)addToSet:(int)loggingContext
{
	OSSpinLockLock(&lock);
	{
		[set addObject:[NSNumber numberWithInt:loggingContext]];
	}
	OSSpinLockUnlock(&lock);
}

- (void)removeFromSet:(int)loggingContext
{
	OSSpinLockLock(&lock);
	{
		[set removeObject:[NSNumber numberWithInt:loggingContext]];
	}
	OSSpinLockUnlock(&lock);
}

- (NSArray *)currentSet
{
	NSArray *result = nil;
	
	OSSpinLockLock(&lock);
	{
		result = [set allObjects];
	}
	OSSpinLockUnlock(&lock);
	
	return result;
}

- (BOOL)isInSet:(int)loggingContext
{
	BOOL result = NO;
	
	OSSpinLockLock(&lock);
	{
		result = [set containsObject:[NSNumber numberWithInt:loggingContext]];
	}
	OSSpinLockUnlock(&lock);
	
	return result;
}

@end

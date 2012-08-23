#import "DDFileLogger.h"

#import <unistd.h>
#import <sys/attr.h>
#import <sys/xattr.h>
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

// Does ARC support support GCD objects?
// It does if the minimum deployment target is iOS 6+ or Mac OS X 10.8+

#if TARGET_OS_IPHONE

  // Compiling for iOS

  #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000 // iOS 6.0 or later
    #define NEEDS_DISPATCH_RETAIN_RELEASE 0
  #else                                         // iOS 5.X or earlier
    #define NEEDS_DISPATCH_RETAIN_RELEASE 1
  #endif

#else

  // Compiling for Mac OS X

  #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080     // Mac OS X 10.8 or later
    #define NEEDS_DISPATCH_RETAIN_RELEASE 0
  #else
    #define NEEDS_DISPATCH_RETAIN_RELEASE 1     // Mac OS X 10.7 or earlier
  #endif

#endif

// We probably shouldn't be using DDLog() statements within the DDLog implementation.
// But we still want to leave our log statements for any future debugging,
// and to allow other developers to trace the implementation (which is a great learning tool).
// 
// So we use primitive logging macros around NSLog.
// We maintain the NS prefix on the macros to be explicit about the fact that we're using NSLog.

#define LOG_LEVEL 2

#define NSLogError(frmt, ...)    do{ if(LOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(LOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(LOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(LOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)

@interface DDLogFileManagerDefault (PrivateAPI)

- (void)deleteOldLogFiles;
- (NSString *)defaultLogsDirectory;

@end

@interface DDFileLogger (PrivateAPI)

- (void)rollLogFileNow;
- (void)maybeRollLogFileDueToAge;
- (void)maybeRollLogFileDueToSize;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLogFileManagerDefault

@synthesize maximumNumberOfLogFiles;

- (id)init
{
	return [self initWithLogsDirectory:nil];
}

- (id)initWithLogsDirectory:(NSString *)aLogsDirectory
{
	if ((self = [super init]))
	{
		maximumNumberOfLogFiles = DEFAULT_LOG_MAX_NUM_LOG_FILES;
		
		if (aLogsDirectory)
			_logsDirectory = [aLogsDirectory copy];
		else
			_logsDirectory = [[self defaultLogsDirectory] copy];
		
		NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
		
		[self addObserver:self forKeyPath:@"maximumNumberOfLogFiles" options:kvoOptions context:nil];
		
		NSLogVerbose(@"DDFileLogManagerDefault: logsDirectory:\n%@", [self logsDirectory]);
		NSLogVerbose(@"DDFileLogManagerDefault: sortedLogFileNames:\n%@", [self sortedLogFileNames]);
	}
	return self;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"maximumNumberOfLogFiles"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	NSNumber *old = [change objectForKey:NSKeyValueChangeOldKey];
	NSNumber *new = [change objectForKey:NSKeyValueChangeNewKey];
	
	if ([old isEqual:new])
	{
		// No change in value - don't bother with any processing.
		return;
	}
	
	if ([keyPath isEqualToString:@"maximumNumberOfLogFiles"])
	{
		NSLogInfo(@"DDFileLogManagerDefault: Responding to configuration change: maximumNumberOfLogFiles");
		
		dispatch_async([DDLog loggingQueue], ^{ @autoreleasepool {
			
			[self deleteOldLogFiles];
		}});
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Deleting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Deletes archived log files that exceed the maximumNumberOfLogFiles configuration value.
**/
- (void)deleteOldLogFiles
{
	NSLogVerbose(@"DDLogFileManagerDefault: deleteOldLogFiles");
	
	NSUInteger maxNumLogFiles = self.maximumNumberOfLogFiles;
	if (maxNumLogFiles == 0)
	{
		// Unlimited - don't delete any log files
		return;
	}
	
	NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
	
	// Do we consider the first file?
	// We are only supposed to be deleting archived files.
	// In most cases, the first file is likely the log file that is currently being written to.
	// So in most cases, we do not want to consider this file for deletion.
	
	NSUInteger count = [sortedLogFileInfos count];
	BOOL excludeFirstFile = NO;
	
	if (count > 0)
	{
		DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:0];
		
		if (!logFileInfo.isArchived)
		{
			excludeFirstFile = YES;
		}
	}
	
	NSArray *sortedArchivedLogFileInfos;
	if (excludeFirstFile)
	{
		count--;
		sortedArchivedLogFileInfos = [sortedLogFileInfos subarrayWithRange:NSMakeRange(1, count)];
	}
	else
	{
		sortedArchivedLogFileInfos = sortedLogFileInfos;
	}
	
	NSUInteger i;
	for (i = maxNumLogFiles; i < count; i++)
	{
		DDLogFileInfo *logFileInfo = [sortedArchivedLogFileInfos objectAtIndex:i];
		
		NSLogInfo(@"DDLogFileManagerDefault: Deleting file: %@", logFileInfo.fileName);
		
		[[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Log Files
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the path to the default logs directory.
 * If the logs directory doesn't exist, this method automatically creates it.
**/
- (NSString *)defaultLogsDirectory
{
#if TARGET_OS_IPHONE
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];
    
#else
	NSString *appName = [[NSProcessInfo processInfo] processName];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSString *logsDirectory = [[basePath stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:appName];

#endif

	return logsDirectory;
}

- (NSString *)logsDirectory
{
	// We could do this check once, during initalization, and not bother again.
	// But this way the code continues to work if the directory gets deleted while the code is running.
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:_logsDirectory])
	{
		NSError *err = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:_logsDirectory
		                               withIntermediateDirectories:YES attributes:nil error:&err])
		{
			NSLogError(@"DDFileLogManagerDefault: Error creating logsDirectory: %@", err);
		}
	}
	
	return _logsDirectory;
}

- (BOOL)isLogFile:(NSString *)fileName
{
	// A log file has a name like "log-<uuid>.txt", where <uuid> is a HEX-string of 6 characters.
	// 
	// For example: log-DFFE99.txt
	
	BOOL hasProperPrefix = [fileName hasPrefix:@"log-"];
	
	BOOL hasProperLength = [fileName length] >= 10;
	
	
	if (hasProperPrefix && hasProperLength)
	{
		NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"];
		
		NSString *hex = [fileName substringWithRange:NSMakeRange(4, 6)];
		NSString *nohex = [hex stringByTrimmingCharactersInSet:hexSet];
		
		if ([nohex length] == 0)
		{
			return YES;
		}
	}
	
	return NO;
}

/**
 * Returns an array of NSString objects,
 * each of which is the filePath to an existing log file on disk.
**/
- (NSArray *)unsortedLogFilePaths
{
	NSString *logsDirectory = [self logsDirectory];
	NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil];
	
	NSMutableArray *unsortedLogFilePaths = [NSMutableArray arrayWithCapacity:[fileNames count]];
	
	for (NSString *fileName in fileNames)
	{
		// Filter out any files that aren't log files. (Just for extra safety)
		
		if ([self isLogFile:fileName])
		{
			NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
			
			[unsortedLogFilePaths addObject:filePath];
		}
	}
	
	return unsortedLogFilePaths;
}

/**
 * Returns an array of NSString objects,
 * each of which is the fileName of an existing log file on disk.
**/
- (NSArray *)unsortedLogFileNames
{
	NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];
	
	NSMutableArray *unsortedLogFileNames = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];
	
	for (NSString *filePath in unsortedLogFilePaths)
	{
		[unsortedLogFileNames addObject:[filePath lastPathComponent]];
	}
	
	return unsortedLogFileNames;
}

/**
 * Returns an array of DDLogFileInfo objects,
 * each representing an existing log file on disk,
 * and containing important information about the log file such as it's modification date and size.
**/
- (NSArray *)unsortedLogFileInfos
{
	NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];
	
	NSMutableArray *unsortedLogFileInfos = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];
	
	for (NSString *filePath in unsortedLogFilePaths)
	{
		DDLogFileInfo *logFileInfo = [[DDLogFileInfo alloc] initWithFilePath:filePath];
		
		[unsortedLogFileInfos addObject:logFileInfo];
	}
	
	return unsortedLogFileInfos;
}

/**
 * Just like the unsortedLogFilePaths method, but sorts the array.
 * The items in the array are sorted by modification date.
 * The first item in the array will be the most recently modified log file.
**/
- (NSArray *)sortedLogFilePaths
{
	NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
	
	NSMutableArray *sortedLogFilePaths = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		[sortedLogFilePaths addObject:[logFileInfo filePath]];
	}
	
	return sortedLogFilePaths;
}

/**
 * Just like the unsortedLogFileNames method, but sorts the array.
 * The items in the array are sorted by modification date.
 * The first item in the array will be the most recently modified log file.
**/
- (NSArray *)sortedLogFileNames
{
	NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
	
	NSMutableArray *sortedLogFileNames = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		[sortedLogFileNames addObject:[logFileInfo fileName]];
	}
	
	return sortedLogFileNames;
}

/**
 * Just like the unsortedLogFileInfos method, but sorts the array.
 * The items in the array are sorted by modification date.
 * The first item in the array will be the most recently modified log file.
**/
- (NSArray *)sortedLogFileInfos
{
	return [[self unsortedLogFileInfos] sortedArrayUsingSelector:@selector(reverseCompareByCreationDate:)];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Creation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Generates a short UUID suitable for use in the log file's name.
 * The result will have six characters, all in the hexadecimal set [0123456789ABCDEF].
**/
- (NSString *)generateShortUUID
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	
	CFStringRef fullStr = CFUUIDCreateString(NULL, uuid);
	NSString *result = (__bridge_transfer NSString *)CFStringCreateWithSubstring(NULL, fullStr, CFRangeMake(0, 6));
	
	CFRelease(fullStr);
	CFRelease(uuid);
	
	return result;
}

/**
 * Generates a new unique log file path, and creates the corresponding log file.
**/
- (NSString *)createNewLogFile
{
	// Generate a random log file name, and create the file (if there isn't a collision)
	
	NSString *logsDirectory = [self logsDirectory];
	do
	{
		NSString *fileName = [NSString stringWithFormat:@"log-%@.txt", [self generateShortUUID]];
		
		NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
		{
			NSLogVerbose(@"DDLogFileManagerDefault: Creating new log file: %@", fileName);
			
			[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
			
			// Since we just created a new log file, we may need to delete some old log files
			[self deleteOldLogFiles];
			
			return filePath;
		}
		
	} while(YES);
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLogFileFormatterDefault

- (id)init
{
	return [self initWithDateFormatter:nil];
}

- (id)initWithDateFormatter:(NSDateFormatter *)aDateFormatter
{
	if ((self = [super init]))
	{
		if (aDateFormatter)
		{
			dateFormatter = aDateFormatter;
		}
		else
		{
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
			[dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
		}
	}
	return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
	NSString *dateAndTime = [dateFormatter stringFromDate:(logMessage->timestamp)];
	
	return [NSString stringWithFormat:@"%@  %@", dateAndTime, logMessage->logMsg];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDFileLogger

- (id)init
{
	DDLogFileManagerDefault *defaultLogFileManager = [[DDLogFileManagerDefault alloc] init];
	
	return [self initWithLogFileManager:defaultLogFileManager];
}

- (id)initWithLogFileManager:(id <DDLogFileManager>)aLogFileManager
{
	if ((self = [super init]))
	{
		maximumFileSize = DEFAULT_LOG_MAX_FILE_SIZE;
		rollingFrequency = DEFAULT_LOG_ROLLING_FREQUENCY;
		
		logFileManager = aLogFileManager;
		
		formatter = [[DDLogFileFormatterDefault alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[currentLogFileHandle synchronizeFile];
	[currentLogFileHandle closeFile];
	
	if (rollingTimer)
	{
		dispatch_source_cancel(rollingTimer);
		rollingTimer = NULL;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize logFileManager;

- (unsigned long long)maximumFileSize
{
	// The design of this method is taken from the DDAbstractLogger implementation.
	// For extensive documentation please refer to the DDAbstractLogger implementation.
	
	// Note: The internal implementation should access the maximumFileSize variable directly,
	// but if we forget to do this, then this method should at least work properly.
	
	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	if (currentQueue == loggerQueue)
	{
		return maximumFileSize;
	}
	else
	{
		dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
		NSAssert(currentQueue != globalLoggingQueue, @"Core architecture requirement failure");
		
		__block unsigned long long result;
		
		dispatch_sync(globalLoggingQueue, ^{
			dispatch_sync(loggerQueue, ^{
				result = maximumFileSize;
			});
		});
		
		return result;
	}
}

- (void)setMaximumFileSize:(unsigned long long)newMaximumFileSize
{
	// The design of this method is taken from the DDAbstractLogger implementation.
	// For documentation please refer to the DDAbstractLogger implementation.
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		maximumFileSize = newMaximumFileSize;
		[self maybeRollLogFileDueToSize];
		
	}};
	
	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	if (currentQueue == loggerQueue)
	{
		block();
	}
	else
	{
		dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
		NSAssert(currentQueue != globalLoggingQueue, @"Core architecture requirement failure");
		
		dispatch_async(globalLoggingQueue, ^{
			dispatch_async(loggerQueue, block);
		});
	}
}

- (NSTimeInterval)rollingFrequency
{
	// The design of this method is taken from the DDAbstractLogger implementation.
	// For documentation please refer to the DDAbstractLogger implementation.
	
	// Note: The internal implementation should access the rollingFrequency variable directly,
	// but if we forget to do this, then this method should at least work properly.
	
	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	if (currentQueue == loggerQueue)
	{
		return rollingFrequency;
	}
	else
	{
		dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
		NSAssert(currentQueue != globalLoggingQueue, @"Core architecture requirement failure");
		
		__block NSTimeInterval result;
		
		dispatch_sync(globalLoggingQueue, ^{
			dispatch_sync(loggerQueue, ^{
				result = rollingFrequency;
			});
		});
		
		return result;
	}
}

- (void)setRollingFrequency:(NSTimeInterval)newRollingFrequency
{
	// The design of this method is taken from the DDAbstractLogger implementation.
	// For documentation please refer to the DDAbstractLogger implementation.
		
	dispatch_block_t block = ^{ @autoreleasepool {
		
		rollingFrequency = newRollingFrequency;
		[self maybeRollLogFileDueToAge];
		
	}};
	
	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	if (currentQueue == loggerQueue)
	{
		block();
	}
	else
	{
		dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
		NSAssert(currentQueue != globalLoggingQueue, @"Core architecture requirement failure");
		
		dispatch_async(globalLoggingQueue, ^{
			dispatch_async(loggerQueue, block);
		});
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Rolling
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)scheduleTimerToRollLogFileDueToAge
{
	if (rollingTimer)
	{
		dispatch_source_cancel(rollingTimer);
		rollingTimer = NULL;
	}
	
	if (currentLogFileInfo == nil || rollingFrequency <= 0.0)
	{
		return;
	}
	
	NSDate *logFileCreationDate = [currentLogFileInfo creationDate];
	
	NSTimeInterval ti = [logFileCreationDate timeIntervalSinceReferenceDate];
	ti += rollingFrequency;
	
	NSDate *logFileRollingDate = [NSDate dateWithTimeIntervalSinceReferenceDate:ti];
	
	NSLogVerbose(@"DDFileLogger: scheduleTimerToRollLogFileDueToAge");
	
	NSLogVerbose(@"DDFileLogger: logFileCreationDate: %@", logFileCreationDate);
	NSLogVerbose(@"DDFileLogger: logFileRollingDate : %@", logFileRollingDate);
	
	rollingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, loggerQueue);
	
	dispatch_source_set_event_handler(rollingTimer, ^{ @autoreleasepool {
		
		[self maybeRollLogFileDueToAge];
		
	}});
	
	#if NEEDS_DISPATCH_RETAIN_RELEASE
	dispatch_source_t theRollingTimer = rollingTimer;
	dispatch_source_set_cancel_handler(rollingTimer, ^{
		dispatch_release(theRollingTimer);
	});
	#endif
	
	uint64_t delay = [logFileRollingDate timeIntervalSinceNow] * NSEC_PER_SEC;
	dispatch_time_t fireTime = dispatch_time(DISPATCH_TIME_NOW, delay);
	
	dispatch_source_set_timer(rollingTimer, fireTime, DISPATCH_TIME_FOREVER, 1.0);
	dispatch_resume(rollingTimer);
}

- (void)rollLogFile
{
	// This method is public.
	// We need to execute the rolling on our logging thread/queue.
	// 
	// The design of this method is taken from the DDAbstractLogger implementation.
	// For documentation please refer to the DDAbstractLogger implementation.
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		[self rollLogFileNow];
	}};
	
	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	if (currentQueue == loggerQueue)
	{
		block();
	}
	else
	{
		dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
		NSAssert(currentQueue != globalLoggingQueue, @"Core architecture requirement failure");
		
		dispatch_async(globalLoggingQueue, ^{
			dispatch_async(loggerQueue, block);
		});
	}
}

- (void)rollLogFileNow
{
	NSLogVerbose(@"DDFileLogger: rollLogFileNow");
	
	
	if (currentLogFileHandle == nil) return;
	
	[currentLogFileHandle synchronizeFile];
	[currentLogFileHandle closeFile];
	currentLogFileHandle = nil;
	
	currentLogFileInfo.isArchived = YES;
	
	if ([logFileManager respondsToSelector:@selector(didRollAndArchiveLogFile:)])
	{
		[logFileManager didRollAndArchiveLogFile:(currentLogFileInfo.filePath)];
	}
	
	currentLogFileInfo = nil;
	
	if (rollingTimer)
	{
		dispatch_source_cancel(rollingTimer);
		rollingTimer = NULL;
	}
}

- (void)maybeRollLogFileDueToAge
{
	if (rollingFrequency > 0.0 && currentLogFileInfo.age >= rollingFrequency)
	{
		NSLogVerbose(@"DDFileLogger: Rolling log file due to age...");
		
		[self rollLogFileNow];
	}
	else
	{
		[self scheduleTimerToRollLogFileDueToAge];
	}
}

- (void)maybeRollLogFileDueToSize
{
	// This method is called from logMessage.
	// Keep it FAST.
	
	// Note: Use direct access to maximumFileSize variable.
	// We specifically wrote our own getter/setter method to allow us to do this (for performance reasons).
	
	if (maximumFileSize > 0)
	{
		unsigned long long fileSize = [currentLogFileHandle offsetInFile];
		
		if (fileSize >= maximumFileSize)
		{
			NSLogVerbose(@"DDFileLogger: Rolling log file due to size (%qu)...", fileSize);
			
			[self rollLogFileNow];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the log file that should be used.
 * If there is an existing log file that is suitable,
 * within the constraints of maximumFileSize and rollingFrequency, then it is returned.
 * 
 * Otherwise a new file is created and returned.
**/
- (DDLogFileInfo *)currentLogFileInfo
{
	if (currentLogFileInfo == nil)
	{
		NSArray *sortedLogFileInfos = [logFileManager sortedLogFileInfos];
		
		if ([sortedLogFileInfos count] > 0)
		{
			DDLogFileInfo *mostRecentLogFileInfo = [sortedLogFileInfos objectAtIndex:0];
			
			BOOL useExistingLogFile = YES;
			BOOL shouldArchiveMostRecent = NO;
			
			if (mostRecentLogFileInfo.isArchived)
			{
				useExistingLogFile = NO;
				shouldArchiveMostRecent = NO;
			}
			else if (maximumFileSize > 0 && mostRecentLogFileInfo.fileSize >= maximumFileSize)
			{
				useExistingLogFile = NO;
				shouldArchiveMostRecent = YES;
			}
			else if (rollingFrequency > 0.0 && mostRecentLogFileInfo.age >= rollingFrequency)
			{
				useExistingLogFile = NO;
				shouldArchiveMostRecent = YES;
			}
			
			if (useExistingLogFile)
			{
				NSLogVerbose(@"DDFileLogger: Resuming logging with file %@", mostRecentLogFileInfo.fileName);
				
				currentLogFileInfo = mostRecentLogFileInfo;
			}
			else
			{
				if (shouldArchiveMostRecent)
				{
					mostRecentLogFileInfo.isArchived = YES;
					
					if ([logFileManager respondsToSelector:@selector(didArchiveLogFile:)])
					{
						[logFileManager didArchiveLogFile:(mostRecentLogFileInfo.filePath)];
					}
				}
			}
		}
		
		if (currentLogFileInfo == nil)
		{
			NSString *currentLogFilePath = [logFileManager createNewLogFile];
			
			currentLogFileInfo = [[DDLogFileInfo alloc] initWithFilePath:currentLogFilePath];
		}
	}
	
	return currentLogFileInfo;
}

- (NSFileHandle *)currentLogFileHandle
{
	if (currentLogFileHandle == nil)
	{
		NSString *logFilePath = [[self currentLogFileInfo] filePath];
		
		currentLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
		[currentLogFileHandle seekToEndOfFile];
		
		if (currentLogFileHandle)
		{
			[self scheduleTimerToRollLogFileDueToAge];
		}
	}
	
	return currentLogFileHandle;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger Protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)logMessage:(DDLogMessage *)logMessage
{
	NSString *logMsg = logMessage->logMsg;
	
	if (formatter)
	{
		logMsg = [formatter formatLogMessage:logMessage];
	}
	
	if (logMsg)
	{
		if (![logMsg hasSuffix:@"\n"])
		{
			logMsg = [logMsg stringByAppendingString:@"\n"];
		}
		
		NSData *logData = [logMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[[self currentLogFileHandle] writeData:logData];
		
		[self maybeRollLogFileDueToSize];
	}
}

- (void)willRemoveLogger
{
	// If you override me be sure to invoke [super willRemoveLogger];
	
	[self rollLogFileNow];
}

- (NSString *)loggerName
{
	return @"cocoa.lumberjack.fileLogger";
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_IPHONE_SIMULATOR
  #define XATTR_ARCHIVED_NAME  @"archived"
#else
  #define XATTR_ARCHIVED_NAME  @"lumberjack.log.archived"
#endif

@implementation DDLogFileInfo

@synthesize filePath;

@dynamic fileName;
@dynamic fileAttributes;
@dynamic creationDate;
@dynamic modificationDate;
@dynamic fileSize;
@dynamic age;

@dynamic isArchived;


#pragma mark Lifecycle

+ (id)logFileWithPath:(NSString *)aFilePath
{
	return [[DDLogFileInfo alloc] initWithFilePath:aFilePath];
}

- (id)initWithFilePath:(NSString *)aFilePath
{
	if ((self = [super init]))
	{
		filePath = [aFilePath copy];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Standard Info
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)fileAttributes
{
	if (fileAttributes == nil)
	{
		fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
	}
	return fileAttributes;
}

- (NSString *)fileName
{
	if (fileName == nil)
	{
		fileName = [filePath lastPathComponent];
	}
	return fileName;
}

- (NSDate *)modificationDate
{
	if (modificationDate == nil)
	{
		modificationDate = [[self fileAttributes] objectForKey:NSFileModificationDate];
	}
	
	return modificationDate;
}

- (NSDate *)creationDate
{
	if (creationDate == nil)
	{
	
	#if TARGET_OS_IPHONE
	
		const char *path = [filePath UTF8String];
		
		struct attrlist attrList;
		memset(&attrList, 0, sizeof(attrList));
		attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
		attrList.commonattr = ATTR_CMN_CRTIME;
		
		struct {
			u_int32_t attrBufferSizeInBytes;
			struct timespec crtime;
		} attrBuffer;
		
		int result = getattrlist(path, &attrList, &attrBuffer, sizeof(attrBuffer), 0);
		if (result == 0)
		{
			double seconds = (double)(attrBuffer.crtime.tv_sec);
			double nanos   = (double)(attrBuffer.crtime.tv_nsec);
			
			NSTimeInterval ti = seconds + (nanos / 1000000000.0);
			
			creationDate = [NSDate dateWithTimeIntervalSince1970:ti];
		}
		else
		{
			NSLogError(@"DDLogFileInfo: creationDate(%@): getattrlist result = %i", self.fileName, result);
		}
		
	#else
		
		creationDate = [[self fileAttributes] objectForKey:NSFileCreationDate];
		
	#endif
		
	}
	return creationDate;
}

- (unsigned long long)fileSize
{
	if (fileSize == 0)
	{
		fileSize = [[[self fileAttributes] objectForKey:NSFileSize] unsignedLongLongValue];
	}
	
	return fileSize;
}

- (NSTimeInterval)age
{
	return [[self creationDate] timeIntervalSinceNow] * -1.0;
}

- (NSString *)description
{
	return [[NSDictionary dictionaryWithObjectsAndKeys:
		self.filePath, @"filePath",
		self.fileName, @"fileName",
		self.fileAttributes, @"fileAttributes",
		self.creationDate, @"creationDate",
		self.modificationDate, @"modificationDate",
		[NSNumber numberWithUnsignedLongLong:self.fileSize], @"fileSize",
		[NSNumber numberWithDouble:self.age], @"age",
		[NSNumber numberWithBool:self.isArchived], @"isArchived",
	nil] description];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Archiving
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isArchived
{
	
#if TARGET_IPHONE_SIMULATOR
	
	// Extended attributes don't work properly on the simulator.
	// So we have to use a less attractive alternative.
	// See full explanation in the header file.
	
	return [self hasExtensionAttributeWithName:XATTR_ARCHIVED_NAME];
	
#else
	
	return [self hasExtendedAttributeWithName:XATTR_ARCHIVED_NAME];
	
#endif
}

- (void)setIsArchived:(BOOL)flag
{
	
#if TARGET_IPHONE_SIMULATOR
	
	// Extended attributes don't work properly on the simulator.
	// So we have to use a less attractive alternative.
	// See full explanation in the header file.
	
	if (flag)
		[self addExtensionAttributeWithName:XATTR_ARCHIVED_NAME];
	else
		[self removeExtensionAttributeWithName:XATTR_ARCHIVED_NAME];
	
#else
	
	if (flag)
		[self addExtendedAttributeWithName:XATTR_ARCHIVED_NAME];
	else
		[self removeExtendedAttributeWithName:XATTR_ARCHIVED_NAME];
	
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Changes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)reset
{
	fileName = nil;
	fileAttributes = nil;
	creationDate = nil;
	modificationDate = nil;
}

- (void)renameFile:(NSString *)newFileName
{
	// This method is only used on the iPhone simulator, where normal extended attributes are broken.
	// See full explanation in the header file.
	
	if (![newFileName isEqualToString:[self fileName]])
	{
		NSString *fileDir = [filePath stringByDeletingLastPathComponent];
		
		NSString *newFilePath = [fileDir stringByAppendingPathComponent:newFileName];
		
		NSLogVerbose(@"DDLogFileInfo: Renaming file: '%@' -> '%@'", self.fileName, newFileName);
		
		NSError *error = nil;
		if (![[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newFilePath error:&error])
		{
			NSLogError(@"DDLogFileInfo: Error renaming file (%@): %@", self.fileName, error);
		}
		
		filePath = newFilePath;
		[self reset];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Attribute Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_IPHONE_SIMULATOR

// Extended attributes don't work properly on the simulator.
// So we have to use a less attractive alternative.
// See full explanation in the header file.

- (BOOL)hasExtensionAttributeWithName:(NSString *)attrName
{
	// This method is only used on the iPhone simulator, where normal extended attributes are broken.
	// See full explanation in the header file.
	
	// Split the file name into components.
	// 
	// log-ABC123.archived.uploaded.txt
	// 
	// 0. log-ABC123
	// 1. archived
	// 2. uploaded
	// 3. txt
	// 
	// So we want to search for the attrName in the components (ignoring the first and last array indexes).
	
	NSArray *components = [[self fileName] componentsSeparatedByString:@"."];
	
	// Watch out for file names without an extension
	
	NSUInteger count = [components count];
	NSUInteger max = (count >= 2) ? count-1 : count;
	
	NSUInteger i;
	for (i = 1; i < max; i++)
	{
		NSString *attr = [components objectAtIndex:i];
		
		if ([attrName isEqualToString:attr])
		{
			return YES;
		}
	}
	
	return NO;
}

- (void)addExtensionAttributeWithName:(NSString *)attrName
{
	// This method is only used on the iPhone simulator, where normal extended attributes are broken.
	// See full explanation in the header file.
	
	if ([attrName length] == 0) return;
	
	// Example:
	// attrName = "archived"
	// 
	// "log-ABC123.txt" -> "log-ABC123.archived.txt"
	
	NSArray *components = [[self fileName] componentsSeparatedByString:@"."];
	
	NSUInteger count = [components count];
	
	NSUInteger estimatedNewLength = [[self fileName] length] + [attrName length] + 1;
	NSMutableString *newFileName = [NSMutableString stringWithCapacity:estimatedNewLength];
	
	if (count > 0)
	{
		[newFileName appendString:[components objectAtIndex:0]];
	}
	
	NSString *lastExt = @"";
	
	NSUInteger i;
	for (i = 1; i < count; i++)
	{
		NSString *attr = [components objectAtIndex:i];
		if ([attr length] == 0)
		{
			continue;
		}
		
		if ([attrName isEqualToString:attr])
		{
			// Extension attribute already exists in file name
			return;
		}
		
		if ([lastExt length] > 0)
		{
			[newFileName appendFormat:@".%@", lastExt];
		}
		
		lastExt = attr;
	}
	
	[newFileName appendFormat:@".%@", attrName];
	
	if ([lastExt length] > 0)
	{
		[newFileName appendFormat:@".%@", lastExt];
	}
	
	[self renameFile:newFileName];
}

- (void)removeExtensionAttributeWithName:(NSString *)attrName
{
	// This method is only used on the iPhone simulator, where normal extended attributes are broken.
	// See full explanation in the header file.
	
	if ([attrName length] == 0) return;
	
	// Example:
	// attrName = "archived"
	// 
	// "log-ABC123.txt" -> "log-ABC123.archived.txt"
	
	NSArray *components = [[self fileName] componentsSeparatedByString:@"."];
	
	NSUInteger count = [components count];
	
	NSUInteger estimatedNewLength = [[self fileName] length];
	NSMutableString *newFileName = [NSMutableString stringWithCapacity:estimatedNewLength];
	
	if (count > 0)
	{
		[newFileName appendString:[components objectAtIndex:0]];
	}
	
	BOOL found = NO;
	
	NSUInteger i;
	for (i = 1; i < count; i++)
	{
		NSString *attr = [components objectAtIndex:i];
		
		if ([attrName isEqualToString:attr])
		{
			found = YES;
		}
		else
		{
			[newFileName appendFormat:@".%@", attr];
		}
	}
	
	if (found)
	{
		[self renameFile:newFileName];
	}
}

#else

- (BOOL)hasExtendedAttributeWithName:(NSString *)attrName
{
	const char *path = [filePath UTF8String];
	const char *name = [attrName UTF8String];
	
	ssize_t result = getxattr(path, name, NULL, 0, 0, 0);
	
	return (result >= 0);
}

- (void)addExtendedAttributeWithName:(NSString *)attrName
{
	const char *path = [filePath UTF8String];
	const char *name = [attrName UTF8String];
	
	int result = setxattr(path, name, NULL, 0, 0, 0);
	
	if (result < 0)
	{
		NSLogError(@"DDLogFileInfo: setxattr(%@, %@): error = %i", attrName, self.fileName, result);
	}
}

- (void)removeExtendedAttributeWithName:(NSString *)attrName
{
	const char *path = [filePath UTF8String];
	const char *name = [attrName UTF8String];
	
	int result = removexattr(path, name, 0);
	
	if (result < 0 && errno != ENOATTR)
	{
		NSLogError(@"DDLogFileInfo: removexattr(%@, %@): error = %i", attrName, self.fileName, result);
	}
}

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Comparisons
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(id)object
{
	if ([object isKindOfClass:[self class]])
	{
		DDLogFileInfo *another = (DDLogFileInfo *)object;
		
		return [filePath isEqualToString:[another filePath]];
	}
	
	return NO;
}

- (NSComparisonResult)reverseCompareByCreationDate:(DDLogFileInfo *)another
{
	NSDate *us = [self creationDate];
	NSDate *them = [another creationDate];
	
	NSComparisonResult result = [us compare:them];
	
	if (result == NSOrderedAscending)
		return NSOrderedDescending;
	
	if (result == NSOrderedDescending)
		return NSOrderedAscending;
	
	return NSOrderedSame;
}

- (NSComparisonResult)reverseCompareByModificationDate:(DDLogFileInfo *)another
{
	NSDate *us = [self modificationDate];
	NSDate *them = [another modificationDate];
	
	NSComparisonResult result = [us compare:them];
	
	if (result == NSOrderedAscending)
		return NSOrderedDescending;
	
	if (result == NSOrderedDescending)
		return NSOrderedAscending;
	
	return NSOrderedSame;
}

@end

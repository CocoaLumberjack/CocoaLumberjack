#import "DDLogLevelsConfig.h"

// We probably shouldn't be using DDLog() statements within the DDLog implementation.
// But we still want to leave our log statements for any future debugging,
// and to allow other developers to trace the implementation (which is a great learning tool).
// 
// So we use primitive logging macros around NSLog.
// We maintain the NS prefix on the macros to be explicit about the fact that we're using NSLog.

#define LOG_LEVEL 4

#define NSLogError(frmt, ...)    do{ if(LOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(LOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(LOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(LOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)

@interface DDLogLevelsConfig (Private)

- (id)initWithFilePath:(NSString *)filePath;
- (void)readFile;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLogLevelsConfig

static dispatch_queue_t configClassQueue;
static NSMutableDictionary *configs;

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		configClassQueue = dispatch_queue_create("DDLogLevelsConfig", NULL);
		configs = [[NSMutableDictionary alloc] init];
	});
}

+ (DDLogLevelsConfig *)config:(NSString *)fileName
{
	if (fileName == nil) return nil;
	
	__block DDLogLevelsConfig *config;
	
	dispatch_sync(configClassQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		config = [configs objectForKey:fileName];
		if (config == nil)
		{
			// Extract FileName and FileExtension
			
			NSString *fn = [fileName stringByDeletingPathExtension];
			NSString *fe = [fileName pathExtension];
			
			NSString *filePath = [[NSBundle mainBundle] pathForResource:fn ofType:fe];
			if (filePath == nil)
			{
				NSLogWarn(@"%@ - Unable to locate config file \"%@\"", [self class], fileName);
				
				// We add NSNull to the dictionary in this case.
				// Because it's unlikely the file is going to appear in the bundle in the future.
				// 
				// But more importantly, this will likely happen for many files in the application,
				// and the developer likely doesn't want to see the warning log statement printed 500 times.
				
				config = nil;
				[configs setObject:[NSNull null] forKey:fileName];
			}
			else
			{
				NSLogInfo(@"%@ - Reading config for fileName \"%@\"", [self class], fileName);
				
				config = [[[DDLogLevelsConfig alloc] initWithFilePath:filePath] autorelease];
				[configs setObject:config forKey:fileName];
			}
		}
		
		[pool drain];
	});
	
	return config;
}

- (id)initWithFilePath:(NSString *)inFilePath
{
	if ((self = [super init]))
	{
		configInstanceQueue = dispatch_queue_create("DDLogLevelsConfig", NULL);
		
		filePath = [inFilePath copy];
		levels = [[NSMutableDictionary alloc] init];
		
		dispatch_async(configInstanceQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[self readFile];
			[pool drain];
		});
	}
	return self;
}

- (void)readFile
{
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
	if (fileHandle == nil)
	{
		NSLogError(@"%@ - Unable to open config file for reading \"%@\"", [self class], [filePath lastPathComponent]);
		
		return;
	}
	
	// Note: The following code could be optimized quite a bit.
	//       I consider this a "first draft" implementation.
	
	// Why not just use readDataToEndOfFile?
	// After all, these config files are very small right?
	// 
	// We all know how easy it is to make a type or have a brain lapse.
	// This might happen when supplying the filename of the config file.
	// 
	// For example:
	// ddLogLevel = [[DDLogLevelsConfig config:@"logger.mp3"] levelFor:THIS_FILE];
	// 
	// Oops, we just read 4.5 MB into memory on an iPod Touch.
	// And that's why we don't use readDataToEndOfFile.
	
	BOOL done = NO;
	NSMutableString *string = [NSMutableString string];
	NSMutableDictionary *defines = [NSMutableDictionary dictionary];
	
	do
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		// Read a chunk of data from the file.
		// We try to supply a length value big enough to read most config files in one request.
		
		NSUInteger readLength = 1024 * 16; // 16 KB
		
		NSData *data = [fileHandle readDataOfLength:readLength];
		if ([data length] == 0)
		{
			if ([string length] == 0)
			{
				// We've read and processed the entire file
				break;
			}
		}
		
		// Convert the raw data into a string, and append to the mutable string we're using for processing.
		
		NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		[string appendString:dataStr];
		[dataStr release];
		
		// Check to see if we've finished reading the file
		
		if ([data length] < readLength)
		{
			done = YES;
			
			// Make life easier by ensuring that all files end with a newline character
			
			[string appendString:@"\n"];
		}
		
		// Extract entire lines.
		// 
		// Unfortunately we can't use componentsSeparatedByString for this purpose.
		// This is due to issues when the chunk we've read falls in the middle of a line.
		// 
		// For example, consider the following line : 
		// "SomeFileName 15 // comment"
		// 
		// Now consider what happens if the end of our read falls somewhere within this line,
		// and we end up with a suffix like one of these:
		// 
		// "SomeFile"             <- Parser will think the level is missing
		// "SomeFileName 1"       <- Parser will get the level wrong
		// "SomeFileName 15 // "  <- Parser will report an error next time when parsing "comment"
		// 
		// So we extract the lines manually, and leave leftovers in the mutable string.
		
		NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSCharacterSet *nonWhitespaceSet = [whitespaceSet invertedSet];
		
		NSMutableArray *lines = [NSMutableArray array];
		
		NSUInteger lineStart = 0;
		NSUInteger i;
		
		for (i = 0; i < [string length]; i++)
		{
			unichar c = [string characterAtIndex:i];
			if (c != '\n')
			{
				// Not a newline character
				continue;
			}
			
			NSRange lineRange = NSMakeRange(lineStart, i - lineStart);
			lineStart = i + 1;
			
			if (lineRange.length == 0)
			{
				// Ignore empty line
				continue;
			}
			
			NSString *line = [string substringWithRange:lineRange];
			
			NSRange nonWhitespaceRange = [line rangeOfCharacterFromSet:nonWhitespaceSet];
			if (nonWhitespaceRange.length == 0)
			{
				// Ignore whitespace-only line
				continue;
			}
			
			[lines addObject:line];
		}
		
		// Remove all the characters we processed from the mutable string.
		// Be sure to keep any valid leftover unprocessed characters.
		
		if (lineStart == i)
		{
			// File or read chunk ended with a newline
			
			[string deleteCharactersInRange:NSMakeRange(0, [string length])];
		}
		else
		{
			// Remember: The code above forcibly ensures that the file ends with a newline.
			//           So if we're here, we know there is more data to read from the file.
			
			[string deleteCharactersInRange:NSMakeRange(0, lineStart)];
		}
		
		// Process the lines
		
		for (NSString *line in lines)
		{
			if ([line hasPrefix:@"//"])
			{
				// Ignore comment line
				continue;
			}
			
			NSArray *components = [line componentsSeparatedByCharactersInSet:whitespaceSet];
			
			// From the documentation for componentsSeparatedBy...:
			// 
			// Adjacent occurrences of the separator characters produce empty strings in the result.
			// Similarly, if the string begins or ends with separator characters,
			// the first or last substring, respectively, is empty.
			// 
			// In other words, it will be common to encounter empty strings, which we should just ignore.
			
			NSString *substr1 = nil;
			NSString *substr2 = nil;
			NSString *substr3 = nil;
			
			for (NSString *component in components)
			{
				if ([component length] == 0)
				{
					continue;
				}
				
				if (substr1 == nil) {
					substr1 = component;
				}
				else if (substr2 == nil) {
					substr2 = component;
				}
				else {
					substr3 = component;
					break;
				}
			}
			
			if (substr1 == nil || substr2 == nil)
			{
				NSLogWarn(@"%@ - Unable to parse line \"%@\"", [self class], line);
				continue;
			}
			
			if ([substr1 isEqualToString:@"DEFINE"])
			{
				// Parsing a DEFINE line
				// We are expecting:
				// 
				// DEFINE <Name> <int>
				
				// Why not just use [substr2 intValue] ?
				// 
				// Because this won't tell us if there is a parsing error, it will just return zero.
				// And a parsing error is very important information we need to know and report to the developer.
				
				NSString *defineName = substr2;
				NSString *defineLevel = substr3;
				
				errno = 0;
				long value = strtol([defineLevel UTF8String], NULL, 10);
				
				if (errno != 0 || value < INT_MIN || value > INT_MAX)
				{
					NSLogWarn(@"%@ - Error parsing level from line \"%@\"", [self class], line);
				}
				else
				{
					NSLogVerbose(@"%@ - DEFINE(\"%@\") -> %i", [self class], defineName, (int)value);
					
					[defines setObject:[NSNumber numberWithInt:(int)value] forKey:defineName];
				}
			}
			else
			{
				// Parsing a normal line.
				// We are expecting:
				// 
				// <FileName>  <LevelAsInt_or_PreviouslyDefinedName>
				
				NSString *fileName = substr1;
				NSString *fileLevel = substr2;
				
				NSNumber *definedLevel = [defines objectForKey:fileLevel];
				if (definedLevel)
				{
					// <FileName> <PreviouslyDefinedName>
					
					NSLogVerbose(@"%@ - FILE(\"%@\") -> %@(%@)", [self class], fileName, fileLevel, definedLevel);
					
					[levels setObject:definedLevel forKey:fileName];
				}
				else
				{
					// <FileName> <LevelAsInt>
					
					// Why not just use [substr2 intValue] ?
					// 
					// Because this won't tell us if there is a parsing error, it will just return zero.
					// And a parsing error is very important information we need to know and report to the developer.
					
					errno = 0;
					long value = strtol([fileLevel UTF8String], NULL, 10);
					
					if (errno != 0 || value < INT_MIN || value > INT_MAX)
					{
						NSLogWarn(@"%@ - Error parsing level from line \"%@\"", [self class], line);
					}
					else
					{
						NSLogVerbose(@"%@ - FILE(\"%@\") -> %i", [self class], fileName, (int)value);
						
						[levels setObject:[NSNumber numberWithInt:(int)value] forKey:fileName];
					}
				}
			}
		}
		
		[pool drain];
		
	} while (!done);
}

- (int)levelFor:(NSString *)fileName
{
	return [self levelFor:fileName withDefault:0];
}

- (int)levelFor:(NSString *)fileName withDefault:(int)valueIfNotPresent
{
	__block int level;
	
	dispatch_sync(configInstanceQueue, ^{
		
		NSNumber *number = [levels objectForKey:fileName];
		if (number) {
			level = [number intValue];
		}
		else {
			level = valueIfNotPresent;
		}
	});
	
	return level;
}

- (void)dealloc
{
	if (configInstanceQueue)
		dispatch_release(configInstanceQueue);
	
	[filePath release];
	[levels release];
	
	[super dealloc];
}

@end

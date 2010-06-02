#import "HTTPDynamicFileResponse.h"
#import "HTTPConnection.h"


@implementation HTTPDynamicFileResponse

static NSOperationQueue *operationQueue;

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
	if(!initialized)
	{
		initialized = YES;
		
		operationQueue = [[NSOperationQueue alloc] init];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// A quick overview of how this class works:
// 
// The HTTPConnection will request data from us via the readDataOfLength method.
// The first time this method is called, we won't have any data available.
// So we'll start a background operation to read data from the file, and then return nil.
// The HTTPConnection, upon receiving a nil response, will then wait for us to inform it of available data.
// 
// Once the background read operation completes, the fileHandleDidReadData method will be called.
// We then copy this data into our mutable buffer, and perform our search and replace algorithm.
// After that we inform the HTTPConnection that we have data by
// calling HTTPConnection's responseHasAvailableData.
// The HTTPConnection will then request our data via the readDataOfLength method.

- (id)initWithFilePath:(NSString *)fpath
         forConnection:(HTTPConnection *)parent
          runLoopModes:(NSArray *)modes
             separator:(NSString *)separatorStr
 replacementDictionary:(NSDictionary *)dict
{
	if((self = [super init]))
	{
		connection = parent; // Parents retain children, children do NOT retain parents
		
		connectionThread = [[NSThread currentThread] retain];
		connectionRunLoopModes = [modes copy];
		
		filePath = [fpath copy];
		fileHandle = [[NSFileHandle fileHandleForReadingAtPath:filePath] retain];
		
		if(fileHandle == nil)
		{
			[self release];
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
		fileLength = (UInt64)[fileSize unsignedLongLongValue];
		
		fileReadOffset = 0;
		connectionReadOffset = 0;
		
		bufferedData  = [[NSMutableData alloc] initWithLength:0];
		available = 0;
		
		asyncReadInProgress = NO;
		
		separator = [[separatorStr dataUsingEncoding:NSUTF8StringEncoding] retain];
		replacementDict = [dict retain];
	}
	return self;
}

- (void)dealloc
{
	[connectionThread release];
	[connectionRunLoopModes release];
	
	[filePath release];
	[fileHandle closeFile];
	[fileHandle release];
	
	[bufferedData release];
	
	[separator release];
	[replacementDict release];
	
	[super dealloc];
}

- (NSString *)filePath
{
	return filePath;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark HTTPResponse Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (UInt64)contentLength
{
	// Ignore - we're using a chunked response
	return 0;
}

- (UInt64)offset
{
	return connectionReadOffset;
}

- (void)setOffset:(UInt64)offset
{
	// Ignore - we're using a chunked response
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	if(available == 0)
	{
		if (!asyncReadInProgress)
		{
			asyncReadInProgress = YES;
			
			NSInvocationOperation *operation;
			operation = [[NSInvocationOperation alloc] initWithTarget:self
			                                                 selector:@selector(readDataInBackground:)
			                                                   object:[NSNumber numberWithUnsignedInteger:length]];
			
			[operationQueue addOperation:operation];
			[operation release];
		}
		
		return nil;
	}
	
	NSUInteger actualLength = MIN(length, available);
	
	connectionReadOffset += actualLength;
	available -= actualLength;
	
	NSRange range = NSMakeRange(0, actualLength);
	NSData *result = [bufferedData subdataWithRange:range];
	
	[bufferedData replaceBytesInRange:range withBytes:NULL length:0];
	
	return result;
}

- (BOOL)isDone
{
	return (fileReadOffset == fileLength) && ([bufferedData length] == 0);
}

- (BOOL)isChunked
{
	return YES;
}

- (void)connectionDidClose
{
	// Prevent any further calls to the connection
	connection = nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Logic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)readDataInBackground:(NSNumber *)lengthNumber
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSUInteger length = [lengthNumber unsignedIntegerValue];
	
	NSData *readData = [fileHandle readDataOfLength:length];
	
	[self performSelector:@selector(fileHandleDidReadData:)
	             onThread:connectionThread
	           withObject:readData
	        waitUntilDone:NO
	                modes:connectionRunLoopModes];
	
	[pool release];
}

- (void)fileHandleDidReadData:(NSData *)readData
{
	[bufferedData appendData:readData];
	
	fileReadOffset += [readData length];
	asyncReadInProgress = NO;
	
	NSUInteger bufLen = [bufferedData length];
	NSUInteger sepLen = [separator length];
	
	// We're going to start looking for the separator where we left off last time,
	// and stop when we get to the point where the separator would no longer fit in the buffer.
	
	NSUInteger i = available;
	NSUInteger stopOffset = (bufLen > sepLen) ? bufLen - sepLen + 1 : 0;
	
	// In order to do the replacement, we need to find the starting and ending separator.
	// For example:
	// 
	// %%USER_NAME%%
	// 
	// Where "%%" is the separator.
	
	BOOL found1 = NO;
	BOOL found2 = NO;
	
	NSUInteger s1 = 0;
	NSUInteger s2 = 0;
	
	while (i < stopOffset)
	{
		const void *subBuffer = [bufferedData mutableBytes] + i;
		
		if (memcmp(subBuffer, [separator bytes], sepLen) == 0)
		{
			if (!found1)
			{
				// Found the first separator
				
				found1 = YES;
				s1 = i;
				i += sepLen;
			}
			else
			{
				// Found the second separator
				
				found2 = YES;
				s2 = i;
				i += sepLen;
			}
			
			if (found1 && found2)
			{
				// We found our separators.
				// Now extract the string between the two separators.
				
				NSRange fullRange = NSMakeRange(s1, (s2 - s1 + sepLen));
				NSRange strRange = NSMakeRange(s1 + sepLen, (s2 - s1 - sepLen));
				
				// Wish we could use the simple subdataWithRange method.
				// But that method copies the bytes...
				// So for performance reasons, we need to use the methods that don't copy the bytes.
				
				void *strBuffer = [bufferedData mutableBytes] + strRange.location;
				NSData *strData = [NSData dataWithBytesNoCopy:strBuffer length:strRange.length freeWhenDone:NO];
				
				NSString *key = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
				if (key)
				{
					// Is there a given replacement for this key?
					
					NSString *value = [replacementDict objectForKey:key];
					if (value)
					{
						// Found the replacement value.
						// Now perform the replacement in the buffer.
						
						NSData *v = [value dataUsingEncoding:NSUTF8StringEncoding];
						
						[bufferedData replaceBytesInRange:fullRange withBytes:[v bytes] length:[v length]];
						
						// The replacement was probably not the same size as what it replaced.
						// So we need to adjust our index accordingly.
						
						NSInteger diff = (NSInteger)[v length] - (NSInteger)fullRange.length;
						i += diff;
					}
				}
				
				found1 = found2 = NO;
			}
		}
		else
		{
			i++;
		}
	}
	
	// We've gone through our buffer now, and performed all the replacements that we could.
	// It's now time to update the amount of available data we have.
	
	if (fileReadOffset == fileLength)
	{
		// We've read in the entire file.
		// So there can be no more replacements.
		
		available = [bufferedData length];
	}
	else
	{
		// There are a couple different situations that we need to take into account here.
		// 
		// Imagine the following file:
		// My name is %%USER_NAME%%
		// 
		// Situation 1:
		// The first chunk of data we read was "My name is %%".
		// So we found the first separator, but not the second.
		// In this case we can only return the data that precedes the first separator.
		// 
		// Situation 2:
		// The first chunk of data we read was "My name is %".
		// So we didn't find any separators, but part of a separator is included in our buffer.
		
		if (found1)
		{
			available = s1;
		}
		else
		{
			available = stopOffset;
		}
	}
	
	// Inform the connection that we have available data.
	// Even if we don't (available == 0) we still do this.
	// Because this will tell the connection to invoke our readDataOfLength method,
	// which will in turn spurn another round of reading from the file.
	
	[connection responseHasAvailableData];
}

@end

#import "HTTPAsyncFileResponse.h"
#import "HTTPConnection.h"


@implementation HTTPAsyncFileResponse

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

// A quick overview of how this class works:
// 
// The HTTPConnection will request data from us via the readDataOfLength method.
// The first time this method is called, we won't have any data available.
// So we'll start a background operation to read data from the file, and then return nil.
// The HTTPConnection, upon receiving a nil response, will then wait for us to inform it of available data.
// 
// Once the background read operation completes, the fileHandleDidReadData method will be called.
// We then inform the HTTPConnection that we have the requested data by
// calling HTTPConnection's responseHasAvailableData.
// The HTTPConnection will then request our data via the readDataOfLength method.

- (id)initWithFilePath:(NSString *)fpath forConnection:(HTTPConnection *)parent runLoopModes:(NSArray *)modes
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
		
		data = nil;
		
		asyncReadInProgress = NO;
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
	[data release];
	[super dealloc];
}

- (UInt64)contentLength
{
	return fileLength;
}

- (UInt64)offset
{
	return connectionReadOffset;
}

- (void)setOffset:(UInt64)offset
{
	[fileHandle seekToFileOffset:offset];
	
	fileReadOffset = offset;
	connectionReadOffset = offset;
	
	// Note: fileHandle is not thread safe, but we don't have to worry about that here.
	// The HTTPConnection won't ever change our offset when we're in the middle of a read.
	// It will request data, and won't move forward from that point until it has received the data.
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	if(data == nil)
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
	
	connectionReadOffset += [data length];
	
	NSData *result = [[data retain] autorelease];
	
	[data release];
	data = nil;
	
	return result;
}

- (BOOL)isDone
{
	return (connectionReadOffset == fileLength);
}

- (NSString *)filePath
{
	return filePath;
}

- (BOOL)isAsynchronous
{
	return YES;
}

- (void)connectionDidClose
{
	// Prevent any further calls to the connection
	connection = nil;
}

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
	data = [readData retain];
	
	fileReadOffset += [data length];
	
	asyncReadInProgress = NO;
	
	[connection responseHasAvailableData];
}

@end

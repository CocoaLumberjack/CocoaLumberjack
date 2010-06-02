#import "HTTPResponse.h"


@implementation HTTPFileResponse

- (id)initWithFilePath:(NSString *)filePathParam
{
	if((self = [super init]))
	{
		filePath = [filePathParam copy];
		fileHandle = [[NSFileHandle fileHandleForReadingAtPath:filePath] retain];
		
		if(fileHandle == nil)
		{
			[self release];
			return nil;
		}
		
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
		fileLength = (UInt64)[fileSize unsignedLongLongValue];
	}
	return self;
}

- (void)dealloc
{
	[filePath release];
	[fileHandle closeFile];
	[fileHandle release];
	[super dealloc];
}

- (UInt64)contentLength
{
	return fileLength;
}

- (UInt64)offset
{
	return (UInt64)[fileHandle offsetInFile];
}

- (void)setOffset:(UInt64)offset
{
	[fileHandle seekToFileOffset:offset];
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	return [fileHandle readDataOfLength:length];
}

- (BOOL)isDone
{
	return ([fileHandle offsetInFile] == fileLength);
}

- (NSString *)filePath
{
	return filePath;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation HTTPDataResponse

- (id)initWithData:(NSData *)dataParam
{
	if((self = [super init]))
	{
		offset = 0;
		data = [dataParam retain];
	}
	return self;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

- (UInt64)contentLength
{
	return (UInt64)[data length];
}

- (UInt64)offset
{
	return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
	offset = (unsigned)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
	NSUInteger remaining = [data length] - offset;
	NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
	
	void *bytes = (void *)([data bytes] + offset);
	
	offset += length;
	
	return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
	return (offset == [data length]);
}

@end

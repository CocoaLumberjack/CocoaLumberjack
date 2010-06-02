#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

@class HTTPConnection;

/**
 * This is an asynchronous version of HTTPFileResponse.
 * It reads data from the given file in a background thread via an NSOperationQueue.
**/

@interface HTTPAsyncFileResponse : NSObject <HTTPResponse>
{
	HTTPConnection *connection;
	NSThread *connectionThread;
	NSArray *connectionRunLoopModes;
	
	NSString *filePath;
	NSFileHandle *fileHandle;
	
	UInt64 fileLength;
	
	UInt64 fileReadOffset;
	UInt64 connectionReadOffset;
	
	NSData *data;
	
	BOOL asyncReadInProgress;
}

- (id)initWithFilePath:(NSString *)filePath forConnection:(HTTPConnection *)connection runLoopModes:(NSArray *)modes;
- (NSString *)filePath;

@end

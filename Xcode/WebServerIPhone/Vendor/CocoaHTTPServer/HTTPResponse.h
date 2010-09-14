#import <Foundation/Foundation.h>


@protocol HTTPResponse

// Returns the length of the data in bytes.
// If you don't know the length in advance, implement the isChunked method and have it return YES.
- (UInt64)contentLength;

// The HTTP server supports range requests in order to allow things like
// file download resumption and optimized streaming on mobile devices.
- (UInt64)offset;
- (void)setOffset:(UInt64)offset;

// Returns the data for the response.
// To support asynchronous responses, read the discussion at the bottom of this header.
- (NSData *)readDataOfLength:(NSUInteger)length;

// Should only return YES after the HTTPConnection has read all available data.
- (BOOL)isDone;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5

@optional

// If you want to add any extra HTTP headers to the response,
// simply return them in a dictionary in this method.
- (NSDictionary *)httpHeaders;

// This method is called from the HTTPConnection class when the connection is closed,
// or when the connection is finished with the response.
// If your response is asynchronous, you should implement this method so you can be sure not to
// invoke HTTPConnection's responseHasAvailableData method after this method is called.
- (void)connectionDidClose;

// If you don't know the content-length in advance,
// implement this method in your custom response class and return YES.
// 
// Important: You should read the discussion at the bottom of this header.
- (BOOL)isChunked;

// Status code for response.
// Allows for responses such as redirect (301), etc.
- (NSInteger)status;

#endif

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPFileResponse : NSObject <HTTPResponse>
{
	NSString *filePath;
	NSFileHandle *fileHandle;
	
	UInt64 fileLength;
}

- (id)initWithFilePath:(NSString *)filePath;
- (NSString *)filePath;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPDataResponse : NSObject <HTTPResponse>
{
	NSUInteger offset;
	NSData *data;
}

- (id)initWithData:(NSData *)data;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPRedirectResponse : NSObject <HTTPResponse>
{
	NSString *redirectPath;
}

- (id)initWithPath:(NSString *)redirectPath;

@end

// Important notice to those implementing custom asynchronous and/or chunked responses:
// 
// HTTPConnection supports asynchronous responses.  All you have to do in your custom response class is
// asynchronously generate the response, and invoke HTTPConnection's responseHasAvailableData method.
// You don't have to wait until you have all of the response ready to invoke this method.  For example, if you
// generate the response in incremental chunks, you could call responseHasAvailableData after generating
// each chunk.  You MUST invoke the responseHasAvailableData method on the proper thread/runloop.  That is,
// the thread/runloop that the HTTPConnection is operating in.  Please see the HTTPAsyncFileResponse class
// for an example of how to properly do this.
// 
// The normal flow of events for an HTTPConnection while responding to a request is like this:
// - Get data from response via readDataOfLength method.
// - Add data to asyncSocket's write queue.
// - Wait for asyncSocket to notify it that the data has been sent.
// - Get more data from response via readDataOfLength method.
// ... continue this cycle until it has sent the entire response.
// 
// With an asynchronous response, the flow is a little different.  When HTTPConnection calls your
// readDataOfLength method, you may or may not have any available data.  If you don't, then simply return nil.
// You should later invoke HTTPConnection's responseHasAvailableData when you have data to send.
// 
// You don't have to keep track of when you return nil in the readDataOfLength method, or how many times you've invoked
// responseHasAvailableData. Just simply call responseHasAvailableData whenever you've generated new data, and
// return nil in your readDataOfLength whenever you don't have any available data in the requested range.
// HTTPConnection will automatically detect when it should be requesting new data and will act appropriately.
// 
// It's important that you also keep in mind that the HTTP server supports range requests.
// The setOffset method is mandatory, and should not be ignored.
// Make sure you take into account the offset within the readDataOfLength method.
// You should also be aware that the HTTPConnection automatically sorts any range requests.
// So if your setOffset method is called with a value of 100, then you can safely release bytes 0-98.
// 
// HTTPConnection can also help you keep your memory footprint small.
// Imagine you're dynamically generating a 10 MB response.  You probably don't want to load all this data into
// RAM, and sit around waiting for HTTPConnection to slowly send it out over the network.  All you need to do
// is pay attention to when HTTPConnection requests more data via readDataOfLength.  This is because HTTPConnection
// will never allow asyncSocket's write queue to get much bigger than READ_CHUNKSIZE bytes.  You should
// consider how you might be able to take advantage of this fact to generate your asynchronous response on demand,
// while at the same time keeping your memory footprint small, and your application lightning fast.
// 
// If you don't know the content-length in advanced, you should also implement the isChunked method.
// This means the response will not include a Content-Length header, and will instead use "Transfer-Encoding: chunked".
// There's a good chance that if your response is asynchronous and dynamic, it's also chunked.
// If your response is chunked, you don't need to worry about range requests.

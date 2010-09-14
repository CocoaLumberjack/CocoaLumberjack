#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
// Note: You may need to add the CFNetwork Framework to your project
#import <CFNetwork/CFNetwork.h>
#endif

@class AsyncSocket;
@class HTTPServer;
@class WebSocket;
@protocol HTTPResponse;


#define HTTPConnectionDidDieNotification  @"HTTPConnectionDidDie"

@interface HTTPConnection : NSObject
{
	AsyncSocket *asyncSocket;
	HTTPServer *server;
	
	CFHTTPMessageRef request;
	int numHeaderLines;
	
	NSString *nonce;
	long lastNC;
	
	NSObject<HTTPResponse> *httpResponse;
	
	NSMutableArray *ranges;
	NSMutableArray *ranges_headers;
	NSString *ranges_boundry;
	int rangeIndex;
	
	UInt64 requestContentLength;
	UInt64 requestContentLengthReceived;
	
	NSMutableArray *responseDataSizes;
}

- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer;

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path;
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path;

- (BOOL)isSecureServer;
- (NSArray *)sslIdentityAndCertificates;

- (BOOL)isPasswordProtected:(NSString *)path;
- (BOOL)useDigestAccessAuthentication;
- (NSString *)realm;
- (NSString *)passwordForUser:(NSString *)username;

- (NSDictionary *)parseParams:(NSString *)query;
- (NSDictionary *)parseGetParams;

- (NSString *)requestURI;

- (NSArray *)directoryIndexFileNames;
- (NSString *)filePathForURI:(NSString *)path;
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path;
- (WebSocket *)webSocketForURI:(NSString *)path;

- (void)prepareForBodyWithSize:(UInt64)contentLength;
- (void)processDataChunk:(NSData *)postDataChunk;

- (void)handleVersionNotSupported:(NSString *)version;
- (void)handleAuthenticationFailed;
- (void)handleResourceNotFound;
- (void)handleInvalidRequest:(NSData *)data;
- (void)handleUnknownMethod:(NSString *)method;

- (NSData *)preprocessResponse:(CFHTTPMessageRef)response;
- (NSData *)preprocessErrorResponse:(CFHTTPMessageRef)response;

- (BOOL)shouldDie;
- (void)die;

@end

@interface HTTPConnection (AsynchronousHTTPResponse)
- (void)responseHasAvailableData;
@end

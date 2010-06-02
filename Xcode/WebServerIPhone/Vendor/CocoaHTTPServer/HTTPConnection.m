#import "AsyncSocket.h"
#import "HTTPServer.h"
#import "HTTPConnection.h"
#import "HTTPResponse.h"
#import "HTTPAuthenticationRequest.h"
#import "DDNumber.h"
#import "DDRange.h"
#import "DDData.h"
#import "HTTPAsyncFileResponse.h"


// Define chunk size used to read in data for responses
// This is how much data will be read from disk into RAM at a time
#if TARGET_OS_IPHONE
  #define READ_CHUNKSIZE  (1024 * 128)
#else
  #define READ_CHUNKSIZE  (1024 * 512)
#endif

// Define chunk size used to read in POST upload data
#if TARGET_OS_IPHONE
  #define POST_CHUNKSIZE  (1024 * 32)
#else
  #define POST_CHUNKSIZE  (1024 * 128)
#endif

// Define the various timeouts (in seconds) for various parts of the HTTP process
#define READ_TIMEOUT          -1
#define WRITE_HEAD_TIMEOUT    30
#define WRITE_BODY_TIMEOUT    -1
#define WRITE_ERROR_TIMEOUT   30
#define NONCE_TIMEOUT        300

// Define the various limits
// LIMIT_MAX_HEADER_LINE_LENGTH: Max length (in bytes) of any single line in a header (including \r\n)
// LIMIT_MAX_HEADER_LINES      : Max number of lines in a single header (including first GET line)
#define LIMIT_MAX_HEADER_LINE_LENGTH  8190
#define LIMIT_MAX_HEADER_LINES         100

// Define the various tags we'll use to differentiate what it is we're currently doing
#define HTTP_REQUEST_HEADER                10
#define HTTP_REQUEST_BODY                  11
#define HTTP_PARTIAL_RESPONSE              20
#define HTTP_PARTIAL_RESPONSE_HEADER       21
#define HTTP_PARTIAL_RESPONSE_BODY         22
#define HTTP_CHUNKED_RESPONSE_HEADER       30
#define HTTP_CHUNKED_RESPONSE_BODY         31
#define HTTP_CHUNKED_RESPONSE_FOOTER       32
#define HTTP_PARTIAL_RANGE_RESPONSE_BODY   40
#define HTTP_PARTIAL_RANGES_RESPONSE_BODY  50
#define HTTP_RESPONSE                      90
#define HTTP_FINAL_RESPONSE                91

// A quick note about the tags:
// 
// The HTTP_RESPONSE and HTTP_FINAL_RESPONSE are designated tags signalling that the response is completely sent.
// That is, in the onSocket:didWriteDataWithTag: method, if the tag is HTTP_RESPONSE or HTTP_FINAL_RESPONSE,
// it is assumed that the response is now completely sent.
// Use HTTP_RESPONSE if it's the end of a response, and you want to start reading more requests afterwards.
// Use HTTP_FINAL_RESPONSE if you wish to terminate the connection after sending the response.
// 
// If you are sending multiple data segments in a custom response, make sure that only the last segment has
// the HTTP_RESPONSE tag. For all other segments prior to the last segment use HTTP_PARTIAL_RESPONSE, or some other
// tag of your own invention.

@interface HTTPConnection (PrivateAPI)
- (CFHTTPMessageRef)newUniRangeResponse:(UInt64)contentLength;
- (CFHTTPMessageRef)newMultiRangeResponse:(UInt64)contentLength;
- (NSData *)chunkedTransferSizeLineForLength:(NSUInteger)length;
- (NSData *)chunkedTransferFooter;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation HTTPConnection

static NSMutableArray *recentNonces;

/**
 * This method is automatically called (courtesy of Cocoa) before the first instantiation of this class.
 * We use it to initialize any static variables.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		// Initialize class variables
		recentNonces = [[NSMutableArray alloc] initWithCapacity:5];
		
		initialized = YES;
	}
}

/**
 * This method is designed to be called by a scheduled timer, and will remove a nonce from the recent nonce list.
 * The nonce to remove should be set as the timer's userInfo.
**/
+ (void)removeRecentNonce:(NSTimer *)aTimer
{
	[recentNonces removeObject:[aTimer userInfo]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Init, Dealloc:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Sole Constructor.
 * Associates this new HTTP connection with the given AsyncSocket.
 * This HTTP connection object will become the socket's delegate and take over responsibility for the socket.
**/
- (id)initWithAsyncSocket:(AsyncSocket *)newSocket forServer:(HTTPServer *)myServer
{
	if((self = [super init]))
	{
		// Take over ownership of the socket
		asyncSocket = [newSocket retain];
		[asyncSocket setDelegate:self];
		
		// Ensure pre-buffering is enabled to improve readDataToData performance
		[asyncSocket enablePreBuffering];
		
		// Store reference to server
		// Note that we do not retain the server. Parents retain their children, children do not retain their parents.
		server = myServer;
		
		// Initialize lastNC (last nonce count)
		// These must increment for each request from the client
		lastNC = 0;
		
		// Create a new HTTP message
		// Note the second parameter is YES, because it will be used for HTTP requests from the client
		request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
		
		numHeaderLines = 0;
		
		responseDataSizes = [[NSMutableArray alloc] initWithCapacity:5];
		
		// Don't start reading the HTTP request here.
		// We are currently running on the thread that the server's listen socket is running on.
		// However, the server may place us on a different thread.
		// We should only read/write to our socket on its proper thread.
		// Instead, we'll wait for the call to onSocket:didConnectToHost:port: which will be on the proper thread.
	}
	return self;
}

/**
 * Standard Deconstructor.
**/
- (void)dealloc
{
	[asyncSocket setDelegate:nil];
	[asyncSocket disconnect];
	[asyncSocket release];
	
	if(request) CFRelease(request);
	
	[nonce release];
	
	if([httpResponse respondsToSelector:@selector(connectionDidClose)])
	{
		[httpResponse connectionDidClose];
	}
	[httpResponse release];
	
	[ranges release];
	[ranges_headers release];
	[ranges_boundry release];
	
	[responseDataSizes release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Method Support
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns whether or not the server will accept messages of a given method
 * at a particular URI.
**/
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	// Override me to support methods such as POST.
	// 
	// Things you may want to consider:
	// - Does the given path represent a resource that is designed to accept this method?
	// - If accepting an upload, is the size of the data being uploaded too big?
	// 
	// For more information, you can always access the CFHTTPMessageRef request variable.
	
	if([method isEqualToString:@"GET"])
		return YES;
	if([method isEqualToString:@"HEAD"])
		return YES;
		
	return NO;
}

/**
 * Returns whether or not the server expects a body from the given method.
 * 
 * In other words, should the server expect a content-length header and associated body from this method.
 * This would be true in the case of a POST, where the client is sending data,
 * or for something like PUT where the client is supposed to be uploading a file.
**/
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)relativePath
{
	// Override me to add support for other methods that expect the client
	// to send a body along with the request header.
	// 
	// You should fall through with a call to [super expectsRequestBodyFromMethod:method atPath:relativePath]
	// 
	// See also: supportsMethod:atPath:
	
	if([method isEqualToString:@"POST"])
		return YES;
	
	if([method isEqualToString:@"PUT"])
		return YES;
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark HTTPS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns whether or not the server is configured to be a secure server.
 * In other words, all connections to this server are immediately secured, thus only secure connections are allowed.
 * This is the equivalent of having an https server, where it is assumed that all connections must be secure.
 * If this is the case, then unsecure connections will not be allowed on this server, and a separate unsecure server
 * would need to be run on a separate port in order to support unsecure connections.
 * 
 * Note: In order to support secure connections, the sslIdentityAndCertificates method must be implemented.
**/
- (BOOL)isSecureServer
{
	// Override me to create an https server...
	
	return NO;
}

/**
 * This method is expected to returns an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
**/
- (NSArray *)sslIdentityAndCertificates
{
	// Override me to provide the proper required SSL identity.
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Password Protection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns whether or not the requested resource is password protected.
 * In this generic implementation, nothing is password protected.
**/
- (BOOL)isPasswordProtected:(NSString *)path
{
	// Override me to provide password protection...
	// You can configure it for the entire server, or based on the current request
	
	return NO;
}

/**
 * Returns whether or not the authentication challenge should use digest access authentication.
 * The alternative is basic authentication.
 * 
 * If at all possible, digest access authentication should be used because it's more secure.
 * Basic authentication sends passwords in the clear and should be avoided unless using SSL/TLS.
**/
- (BOOL)useDigestAccessAuthentication
{
	// Override me to customize the authentication scheme
	// Make sure you understand the security risks of using the weaker basic authentication
	
	return YES;
}

/**
 * Returns the authentication realm.
 * In this generic implmentation, a default realm is used for the entire server.
**/
- (NSString *)realm
{
	// Override me to provide a custom realm...
	// You can configure it for the entire server, or based on the current request
	
	return @"defaultRealm@host.com";
}

/**
 * Returns the password for the given username.
**/
- (NSString *)passwordForUser:(NSString *)username
{
	// Override me to provide proper password authentication
	// You can configure a password for the entire server, or custom passwords for users and/or resources
	
	// Security Note:
	// A nil password means no access at all. (Such as for user doesn't exist)
	// An empty string password is allowed, and will be treated as any other password. (To support anonymous access)
	
	return nil;
}

/**
 * Generates and returns an authentication nonce.
 * A nonce is a  server-specified string uniquely generated for each 401 response.
 * The default implementation uses a single nonce for each session.
**/
- (NSString *)generateNonce
{
	// We use the Core Foundation UUID class to generate a nonce value for us
	// UUIDs (Universally Unique Identifiers) are 128-bit values guaranteed to be unique.
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	NSString *newNonce = [NSMakeCollectable(CFUUIDCreateString(NULL, theUUID)) autorelease];
	CFRelease(theUUID);
	
	// We have to remember that the HTTP protocol is stateless.
	// Even though with version 1.1 persistent connections are the norm, they are not guaranteed.
	// Thus if we generate a nonce for this connection,
	// it should be honored for other connections in the near future.
	// 
	// In fact, this is absolutely necessary in order to support QuickTime.
	// When QuickTime makes it's initial connection, it will be unauthorized, and will receive a nonce.
	// It then disconnects, and creates a new connection with the nonce, and proper authentication.
	// If we don't honor the nonce for the second connection, QuickTime will repeat the process and never connect.
	
	[recentNonces addObject:newNonce];
	
	[NSTimer scheduledTimerWithTimeInterval:NONCE_TIMEOUT
									 target:[HTTPConnection class]
								   selector:@selector(removeRecentNonce:)
								   userInfo:newNonce
									repeats:NO];
	return newNonce;
}

/**
 * Returns whether or not the user is properly authenticated.
**/
- (BOOL)isAuthenticated
{
	// Extract the authentication information from the Authorization header
	HTTPAuthenticationRequest *auth = [[[HTTPAuthenticationRequest alloc] initWithRequest:request] autorelease];
	
	if([self useDigestAccessAuthentication])
	{
		// Digest Access Authentication (RFC 2617)
		
		if(![auth isDigest])
		{
			// User didn't send proper digest access authentication credentials
			return NO;
		}
		
		if([auth username] == nil)
		{
			// The client didn't provide a username
			// Most likely they didn't provide any authentication at all
			return NO;
		}
		
		NSString *password = [self passwordForUser:[auth username]];
		if(password == nil)
		{
			// No access allowed (username doesn't exist in system)
			return NO;
		}
		
		NSString *method = [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(request)) autorelease];
		
		NSURL *absoluteUrl = [NSMakeCollectable(CFHTTPMessageCopyRequestURL(request)) autorelease];
		NSString *url = [absoluteUrl relativeString];
		
		if(![url isEqualToString:[auth uri]])
		{
			// Requested URL and Authorization URI do not match
			// This could be a replay attack
			// IE - attacker provides same authentication information, but requests a different resource
			return NO;
		}
		
		// The nonce the client provided will most commonly be stored in our local (cached) nonce variable
		if(![nonce isEqualToString:[auth nonce]])
		{
			// The given nonce may be from another connection
			// We need to search our list of recent nonce strings that have been recently distributed
			if([recentNonces containsObject:[auth nonce]])
			{
				// Store nonce in local (cached) nonce variable to prevent array searches in the future
				[nonce release];
				nonce = [[auth nonce] copy];
				
				// The client has switched to using a different nonce value
				// This may happen if the client tries to get a file in a directory with different credentials.
				// The previous credentials wouldn't work, and the client would receive a 401 error
				// along with a new nonce value. The client then uses this new nonce value and requests the file again.
				// Whatever the case may be, we need to reset lastNC, since that variable is on a per nonce basis.
				lastNC = 0;
			}
			else
			{
				// We have no knowledge of ever distributing such a nonce.
				// This could be a replay attack from a previous connection in the past.
				return NO;
			}
		}
		
		long authNC = strtol([[auth nc] UTF8String], NULL, 16);
		
		if(authNC <= lastNC)
		{
			// The nc value (nonce count) hasn't been incremented since the last request.
			// This could be a replay attack.
			return NO;
		}
		lastNC = authNC;
		
		NSString *HA1str = [NSString stringWithFormat:@"%@:%@:%@", [auth username], [auth realm], password];
		NSString *HA2str = [NSString stringWithFormat:@"%@:%@", method, [auth uri]];
		
		NSString *HA1 = [[[HA1str dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
		
		NSString *HA2 = [[[HA2str dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
		
		NSString *responseStr = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
								 HA1, [auth nonce], [auth nc], [auth cnonce], [auth qop], HA2];
		
		NSString *response = [[[responseStr dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
		
		return [response isEqualToString:[auth response]];
	}
	else
	{
		// Basic Authentication
		
		if(![auth isBasic])
		{
			// User didn't send proper base authentication credentials
			return NO;
		}
		
		// Decode the base 64 encoded credentials
		NSString *base64Credentials = [auth base64Credentials];
		
		NSData *temp = [[base64Credentials dataUsingEncoding:NSUTF8StringEncoding] base64Decoded];
		
		NSString *credentials = [[[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding] autorelease];
		
		// The credentials should be of the form "username:password"
		// The username is not allowed to contain a colon
		
		NSRange colonRange = [credentials rangeOfString:@":"];
		
		if(colonRange.length == 0)
		{
			// Malformed credentials
			return NO;
		}
		
		NSString *credUsername = [credentials substringToIndex:colonRange.location];
		NSString *credPassword = [credentials substringFromIndex:(colonRange.location + colonRange.length)];
		
		NSString *password = [self passwordForUser:credUsername];
		if(password == nil)
		{
			// No access allowed (username doesn't exist in system)
			return NO;
		}
		
		return [password isEqualToString:credPassword];
	}
}

/**
 * Adds a digest access authentication challenge to the given response.
**/
- (void)addDigestAuthChallenge:(CFHTTPMessageRef)response
{
	NSString *authFormat = @"Digest realm=\"%@\", qop=\"auth\", nonce=\"%@\"";
	NSString *authInfo = [NSString stringWithFormat:authFormat, [self realm], [self generateNonce]];
	
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("WWW-Authenticate"), (CFStringRef)authInfo);
}

/**
 * Adds a basic authentication challenge to the given response.
**/
- (void)addBasicAuthChallenge:(CFHTTPMessageRef)response
{
	NSString *authFormat = @"Basic realm=\"%@\"";
	NSString *authInfo = [NSString stringWithFormat:authFormat, [self realm]];
	
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("WWW-Authenticate"), (CFStringRef)authInfo);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** 
 * Parses the query variables in the request URI. 
 * 
 * For example, if the request URI was "search?q=John%20Mayer%20Trio&num=50" 
 * then this method would return the following dictionary: 
 * { 
 *   q = "John Mayer Trio" 
 *   num = "50" 
 * } 
**/ 
- (NSDictionary *)parseRequestQuery 
{
	if(request == NULL) return nil;
	if(!CFHTTPMessageIsHeaderComplete(request)) return nil;
	
	CFURLRef url = CFHTTPMessageCopyRequestURL(request);
	if(url == NULL) return nil;
	
	NSString *query = [NSMakeCollectable(CFURLCopyQueryString(url, NULL)) autorelease];
	
	NSArray *components = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[components count]];
	
	NSUInteger i;
	for(i = 0; i < [components count]; i++)
	{ 
		NSString *component = [components objectAtIndex:i];
		if([component length] > 0)
		{
			NSRange range = [component rangeOfString:@"="];
			if(range.location != NSNotFound)
			{ 
				NSString *escapedKey = [component substringToIndex:(range.location + 0)]; 
				NSString *escapedValue = [component substringFromIndex:(range.location + 1)];
				
				if([escapedKey length] > 0)
				{
					CFStringRef k, v;
					
					k = CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)escapedKey, CFSTR(""));
					v = CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)escapedValue, CFSTR(""));
					
					NSString *key, *value;
					
					key   = [NSMakeCollectable(k) autorelease];
					value = [NSMakeCollectable(v) autorelease];
					
					if(key)
					{
						if(value)
							[result setObject:value forKey:key]; 
						else 
							[result setObject:[NSNull null] forKey:key]; 
					}
				}
			}
		}
	}
	
	CFRelease(url); 
	return result; 
}

/**
 * Attempts to parse the given range header into a series of sequential non-overlapping ranges.
 * If successfull, the variables 'ranges' and 'rangeIndex' will be updated, and YES will be returned.
 * Otherwise, NO is returned, and the range request should be ignored.
 **/
- (BOOL)parseRangeRequest:(NSString *)rangeHeader withContentLength:(UInt64)contentLength
{
	// Examples of byte-ranges-specifier values (assuming an entity-body of length 10000):
	// 
	// - The first 500 bytes (byte offsets 0-499, inclusive):  bytes=0-499
	// 
	// - The second 500 bytes (byte offsets 500-999, inclusive): bytes=500-999
	// 
	// - The final 500 bytes (byte offsets 9500-9999, inclusive): bytes=-500
	// 
	// - Or bytes=9500-
	// 
	// - The first and last bytes only (bytes 0 and 9999):  bytes=0-0,-1
	// 
	// - Several legal but not canonical specifications of the second 500 bytes (byte offsets 500-999, inclusive):
	// bytes=500-600,601-999
	// bytes=500-700,601-999
	// 
	
	NSRange eqsignRange = [rangeHeader rangeOfString:@"="];
	
	if(eqsignRange.location == NSNotFound) return NO;
	
	NSUInteger tIndex = eqsignRange.location;
	NSUInteger fIndex = eqsignRange.location + eqsignRange.length;
	
	NSString *rangeType  = [[[rangeHeader substringToIndex:tIndex] mutableCopy] autorelease];
	NSString *rangeValue = [[[rangeHeader substringFromIndex:fIndex] mutableCopy] autorelease];
	
	CFStringTrimWhitespace((CFMutableStringRef)rangeType);
	CFStringTrimWhitespace((CFMutableStringRef)rangeValue);
	
	if([rangeType caseInsensitiveCompare:@"bytes"] != NSOrderedSame) return NO;
	
	NSArray *rangeComponents = [rangeValue componentsSeparatedByString:@","];
	
	if([rangeComponents count] == 0) return NO;
	
	[ranges release];
	ranges = [[NSMutableArray alloc] initWithCapacity:[rangeComponents count]];
	
	rangeIndex = 0;
	
	// Note: We store all range values in the form of DDRange structs, wrapped in NSValue objects.
	// Since DDRange consists of UInt64 values, the range extends up to 16 exabytes.
	
	NSUInteger i;
	for(i = 0; i < [rangeComponents count]; i++)
	{
		NSString *rangeComponent = [rangeComponents objectAtIndex:i];
		
		NSRange dashRange = [rangeComponent rangeOfString:@"-"];
		
		if(dashRange.location == NSNotFound)
		{
			// We're dealing with an individual byte number
			
			UInt64 byteIndex;
			if(![NSNumber parseString:rangeComponent intoUInt64:&byteIndex]) return NO;
			
			if(byteIndex >= contentLength) return NO;
			
			[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(byteIndex, 1)]];
		}
		else
		{
			// We're dealing with a range of bytes
			
			tIndex = dashRange.location;
			fIndex = dashRange.location + dashRange.length;
			
			NSString *r1str = [rangeComponent substringToIndex:tIndex];
			NSString *r2str = [rangeComponent substringFromIndex:fIndex];
			
			UInt64 r1, r2;
			
			BOOL hasR1 = [NSNumber parseString:r1str intoUInt64:&r1];
			BOOL hasR2 = [NSNumber parseString:r2str intoUInt64:&r2];
			
			if(!hasR1)
			{
				// We're dealing with a "-[#]" range
				// 
				// r2 is the number of ending bytes to include in the range
				
				if(!hasR2) return NO;
				if(r2 > contentLength) return NO;
				
				UInt64 startIndex = contentLength - r2;
				
				[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(startIndex, r2)]];
			}
			else if(!hasR2)
			{
				// We're dealing with a "[#]-" range
				// 
				// r1 is the starting index of the range, which goes all the way to the end
				
				if(r1 >= contentLength) return NO;
				
				[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(r1, contentLength - r1)]];
			}
			else
			{
				// We're dealing with a normal "[#]-[#]" range
				// 
				// Note: The range is inclusive. So 0-1 has a length of 2 bytes.
				
				if(r1 > r2) return NO;
				if(r2 >= contentLength) return NO;
				
				[ranges addObject:[NSValue valueWithDDRange:DDMakeRange(r1, r2 - r1 + 1)]];
			}
		}
	}
	
	if([ranges count] == 0) return NO;
	
	// Now make sure none of the ranges overlap
	
	for(i = 0; i < [ranges count] - 1; i++)
	{
		DDRange range1 = [[ranges objectAtIndex:i] ddrangeValue];
		
		NSUInteger j;
		for(j = i+1; j < [ranges count]; j++)
		{
			DDRange range2 = [[ranges objectAtIndex:j] ddrangeValue];
			
			DDRange iRange = DDIntersectionRange(range1, range2);
			
			if(iRange.length != 0)
			{
				return NO;
			}
		}
	}
	
	// Sort the ranges
	
	[ranges sortUsingSelector:@selector(ddrangeCompare:)];
	
	return YES;
}

- (NSString *)requestURI
{
	if (request == NULL) return nil;
	
	NSURL *uri = [NSMakeCollectable(CFHTTPMessageCopyRequestURL(request)) autorelease];
	
	return [uri relativeString];
}

/**
 * This method is called after a full HTTP request has been received.
 * The current request is in the CFHTTPMessage request variable.
**/
- (void)replyToHTTPRequest
{
//	NSData *tempData = (NSData *)CFHTTPMessageCopySerializedMessage(request);
//	NSString *tempStr = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
//	
//	NSLog(@"HTTPConnection:%p replyToHTTPRequest:\n%@", self, tempStr);
//	
//	[tempStr release];
//	[tempData release];
	
	// Check the HTTP version - if it's anything but HTTP version 1.1, we don't support it
	NSString *version = [NSMakeCollectable(CFHTTPMessageCopyVersion(request)) autorelease];
	if(!version || ![version isEqualToString:(NSString *)kCFHTTPVersion1_1])
	{
		[self handleVersionNotSupported:version];
		return;
	}
	
	// Extract the method
	NSString *method = [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(request)) autorelease];
	
	// Note: We already checked to ensure the method was supported in onSocket:didReadData:withTag:
	
	// Extract requested URI
	NSString *uri = [self requestURI];
	
	// Check Authentication (if needed)
	// If not properly authenticated for resource, issue Unauthorized response
	if([self isPasswordProtected:uri] && ![self isAuthenticated])
	{
		[self handleAuthenticationFailed];
		return;
	}
	
	// Respond properly to HTTP 'GET' and 'HEAD' commands
	httpResponse = [[self httpResponseForMethod:method URI:uri] retain];
	
	if(httpResponse == nil)
	{
		[self handleResourceNotFound];
		return;
	}
	
	BOOL isChunked = NO;
	
	if([httpResponse respondsToSelector:@selector(isChunked)])
	{
		isChunked = [httpResponse isChunked];
	}
	
	// If a response is "chunked", this simply means the HTTPResponse object
	// doesn't know the content-length in advance.
	
	UInt64 contentLength = 0;
	
	if(!isChunked)
	{
		contentLength = [httpResponse contentLength];
	}
	
	// Check for specific range request
	NSString *rangeHeader = [NSMakeCollectable(CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Range"))) autorelease];
	
	BOOL isRangeRequest = NO;
	
	// If the response is "chunked" then we don't know the exact content-length.
	// This means we'll be unable to process any range requests.
	// This is because range requests might include a range like "give me the last 100 bytes"
	
	if(!isChunked && rangeHeader)
	{
		if([self parseRangeRequest:rangeHeader withContentLength:contentLength])
		{
			isRangeRequest = YES;
		}
	}
	
	CFHTTPMessageRef response;
	
	if(!isRangeRequest)
	{
		// Status Code 200 - OK
		response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
		
		if(isChunked)
		{
			CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Transfer-Encoding"), CFSTR("chunked"));
		}
		else
		{
			NSString *contentLengthStr = [NSString stringWithFormat:@"%qu", contentLength];
			CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (CFStringRef)contentLengthStr);
		}
	}
	else
	{
		if([ranges count] == 1)
		{
			response = [self newUniRangeResponse:contentLength];
		}
		else
		{
			response = [self newMultiRangeResponse:contentLength];
		}
	}
	
	BOOL isZeroLengthResponse = !isChunked && (contentLength == 0);
    
	// If they issue a 'HEAD' command, we don't have to include the file
	// If they issue a 'GET' command, we need to include the file
	
	if([method isEqual:@"HEAD"] || isZeroLengthResponse)
	{
		NSData *responseData = [self preprocessResponse:response];
		[asyncSocket writeData:responseData withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_RESPONSE];
	}
	else
	{
		// Write the header response
		NSData *responseData = [self preprocessResponse:response];
		[asyncSocket writeData:responseData withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_PARTIAL_RESPONSE_HEADER];
		
		// Now we need to send the body of the response
		if(!isRangeRequest)
		{
			// Regular request
			NSData *data = [httpResponse readDataOfLength:READ_CHUNKSIZE];
			
			if([data length] > 0)
			{
				[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
				
				if(isChunked)
				{
					NSData *chunkSize = [self chunkedTransferSizeLineForLength:[data length]];
					[asyncSocket writeData:chunkSize withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_CHUNKED_RESPONSE_HEADER];
					
					[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:HTTP_CHUNKED_RESPONSE_BODY];
					
					if([httpResponse isDone])
					{
						NSData *footer = [self chunkedTransferFooter];
						[asyncSocket writeData:footer withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_RESPONSE];
					}
					else
					{
						NSData *footer = [AsyncSocket CRLFData];
						[asyncSocket writeData:footer withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_CHUNKED_RESPONSE_FOOTER];
					}
				}
				else
				{
					long tag = [httpResponse isDone] ? HTTP_RESPONSE : HTTP_PARTIAL_RESPONSE_BODY;
					[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:tag];
				}
			}
		}
		else
		{
			// Client specified a byte range in request
			
			if([ranges count] == 1)
			{
				// Client is requesting a single range
				DDRange range = [[ranges objectAtIndex:0] ddrangeValue];
				
				[httpResponse setOffset:range.location];
				
				NSUInteger bytesToRead = range.length < READ_CHUNKSIZE ? (NSUInteger)range.length : READ_CHUNKSIZE;
				
				NSData *data = [httpResponse readDataOfLength:bytesToRead];
				
				if([data length] > 0)
				{
					[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
					
					long tag = [data length] == range.length ? HTTP_RESPONSE : HTTP_PARTIAL_RANGE_RESPONSE_BODY;
					[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:tag];
				}
			}
			else
			{
				// Client is requesting multiple ranges
				// We have to send each range using multipart/byteranges
				
				// Write range header
				NSData *rangeHeaderData = [ranges_headers objectAtIndex:0];
				[asyncSocket writeData:rangeHeaderData withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_PARTIAL_RESPONSE_HEADER];
				
				// Start writing range body
				DDRange range = [[ranges objectAtIndex:0] ddrangeValue];
				
				[httpResponse setOffset:range.location];
				
				NSUInteger bytesToRead = range.length < READ_CHUNKSIZE ? (NSUInteger)range.length : READ_CHUNKSIZE;
				
				NSData *data = [httpResponse readDataOfLength:bytesToRead];
				
				if([data length] > 0)
				{
					[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
					
					[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:HTTP_PARTIAL_RANGES_RESPONSE_BODY];
				}
			}
		}
	}
	
	CFRelease(response);
}

/**
 * Prepares a single-range response.
 * 
 * Note: The returned CFHTTPMessageRef is owned by the sender, who is responsible for releasing it.
**/
- (CFHTTPMessageRef)newUniRangeResponse:(UInt64)contentLength
{
	// Status Code 206 - Partial Content
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 206, NULL, kCFHTTPVersion1_1);
	
	DDRange range = [[ranges objectAtIndex:0] ddrangeValue];
	
	NSString *contentLengthStr = [NSString stringWithFormat:@"%qu", range.length];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (CFStringRef)contentLengthStr);
	
	NSString *rangeStr = [NSString stringWithFormat:@"%qu-%qu", range.location, DDMaxRange(range) - 1];
	NSString *contentRangeStr = [NSString stringWithFormat:@"bytes %@/%qu", rangeStr, contentLength];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Range"), (CFStringRef)contentRangeStr);
	
	return response;
}

/**
 * Prepares a multi-range response.
 * 
 * Note: The returned CFHTTPMessageRef is owned by the sender, who is responsible for releasing it.
**/
- (CFHTTPMessageRef)newMultiRangeResponse:(UInt64)contentLength
{
	// Status Code 206 - Partial Content
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 206, NULL, kCFHTTPVersion1_1);
	
	// We have to send each range using multipart/byteranges
	// So each byterange has to be prefix'd and suffix'd with the boundry
	// Example:
	// 
	// HTTP/1.1 206 Partial Content
	// Content-Length: 220
	// Content-Type: multipart/byteranges; boundary=4554d24e986f76dd6
	// 
	// 
	// --4554d24e986f76dd6
	// Content-Range: bytes 0-25/4025
	// 
	// [...]
	// --4554d24e986f76dd6
	// Content-Range: bytes 3975-4024/4025
	// 
	// [...]
	// --4554d24e986f76dd6--
	
	ranges_headers = [[NSMutableArray alloc] initWithCapacity:[ranges count]];
	
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	ranges_boundry = NSMakeCollectable(CFUUIDCreateString(NULL, theUUID));
	CFRelease(theUUID);
	
	NSString *startingBoundryStr = [NSString stringWithFormat:@"\r\n--%@\r\n", ranges_boundry];
	NSString *endingBoundryStr = [NSString stringWithFormat:@"\r\n--%@--\r\n", ranges_boundry];
	
	UInt64 actualContentLength = 0;
	
	NSUInteger i;
	for(i = 0; i < [ranges count]; i++)
	{
		DDRange range = [[ranges objectAtIndex:i] ddrangeValue];
		
		NSString *rangeStr = [NSString stringWithFormat:@"%qu-%qu", range.location, DDMaxRange(range) - 1];
		NSString *contentRangeVal = [NSString stringWithFormat:@"bytes %@/%qu", rangeStr, contentLength];
		NSString *contentRangeStr = [NSString stringWithFormat:@"Content-Range: %@\r\n\r\n", contentRangeVal];
		
		NSString *fullHeader = [startingBoundryStr stringByAppendingString:contentRangeStr];
		NSData *fullHeaderData = [fullHeader dataUsingEncoding:NSUTF8StringEncoding];
		
		[ranges_headers addObject:fullHeaderData];
		
		actualContentLength += [fullHeaderData length];
		actualContentLength += range.length;
	}
	
	NSData *endingBoundryData = [endingBoundryStr dataUsingEncoding:NSUTF8StringEncoding];
	
	actualContentLength += [endingBoundryData length];
	
	NSString *contentLengthStr = [NSString stringWithFormat:@"%qu", actualContentLength];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (CFStringRef)contentLengthStr);
	
	NSString *contentTypeStr = [NSString stringWithFormat:@"multipart/byteranges; boundary=%@", ranges_boundry];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Type"), (CFStringRef)contentTypeStr);
	
	return response;
}

/**
 * Returns the chunk size line that must precede each chunk of data when using chunked transfer encoding.
 * This consists of the size of the data, in hexadecimal, followed by a CRLF.
**/
- (NSData *)chunkedTransferSizeLineForLength:(NSUInteger)length
{
	return [[NSString stringWithFormat:@"%lx\r\n", (unsigned long)length] dataUsingEncoding:NSUTF8StringEncoding];
}

/**
 * Returns the data that signals the end of a chunked transfer.
**/
- (NSData *)chunkedTransferFooter
{
	// Each data chunk is preceded by a size line (in hex and including a CRLF),
	// followed by the data itself, followed by another CRLF.
	// After every data chunk has been sent, a zero size line is sent,
	// followed by optional footer (which are just more headers),
	// and followed by a CRLF on a line by itself.
	
	return [@"\r\n0\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
}

/**
 * Returns the number of bytes of the http response body that are sitting in asyncSocket's write queue.
 * 
 * We keep track of this information in order to keep our memory footprint low while
 * working with asynchronous HTTPResponse objects.
**/
- (NSUInteger)writeQueueSize
{
	NSUInteger result = 0;
	
	NSUInteger i;
	for(i = 0; i < [responseDataSizes count]; i++)
	{
		result += [[responseDataSizes objectAtIndex:i] unsignedIntegerValue];
	}
	
	return result;
}

/**
 * Sends more data, if needed, without growing the write queue over its approximate size limit.
 * The last chunk of the response body will be sent with a tag of HTTP_RESPONSE.
 * 
 * This method should only be called for standard (non-range) responses.
**/
- (void)continueSendingStandardResponseBody
{
	// This method is called when either asyncSocket has finished writing one of the response data chunks,
	// or when an asynchronous HTTPResponse object informs us that it has more available data for us to send.
	// In the case of the asynchronous HTTPResponse, we don't want to blindly grab the new data,
	// and shove it onto asyncSocket's write queue.
	// Doing so could negatively affect the memory footprint of the application.
	// Instead, we always ensure that we place no more than READ_CHUNKSIZE bytes onto the write queue.
	// 
	// Note that this does not affect the rate at which the HTTPResponse object may generate data.
	// The HTTPResponse is free to do as it pleases, and this is up to the application's developer.
	// If the memory footprint is a concern, the developer creating the custom HTTPResponse object may freely
	// use the calls to readDataOfLength as an indication to start generating more data.
	// This provides an easy way for the HTTPResponse object to throttle its data allocation in step with the rate
	// at which the socket is able to send it.
	
	NSUInteger writeQueueSize = [self writeQueueSize];
	
	if(writeQueueSize >= READ_CHUNKSIZE) return;
	
	NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
	NSData *data = [httpResponse readDataOfLength:available];
	
	if([data length] > 0)
	{
		[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
		
		BOOL isChunked = NO;
		
		if([httpResponse respondsToSelector:@selector(isChunked)])
		{
			isChunked = [httpResponse isChunked];
		}
		
		if(isChunked)
		{
			NSData *chunkSize = [self chunkedTransferSizeLineForLength:[data length]];
			[asyncSocket writeData:chunkSize withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_CHUNKED_RESPONSE_HEADER];
			
			[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:HTTP_CHUNKED_RESPONSE_BODY];
			
			if([httpResponse isDone])
			{
				NSData *footer = [self chunkedTransferFooter];
				[asyncSocket writeData:footer withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_RESPONSE];
			}
			else
			{
				NSData *footer = [AsyncSocket CRLFData];
				[asyncSocket writeData:footer withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_CHUNKED_RESPONSE_FOOTER];
			}
		}
		else
		{
			long tag = [httpResponse isDone] ? HTTP_RESPONSE : HTTP_PARTIAL_RESPONSE_BODY;
			[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:tag];
		}
	}
}

/**
 * Sends more data, if needed, without growing the write queue over its approximate size limit.
 * The last chunk of the response body will be sent with a tag of HTTP_RESPONSE.
 * 
 * This method should only be called for single-range responses.
**/
- (void)continueSendingSingleRangeResponseBody
{
	// This method is called when either asyncSocket has finished writing one of the response data chunks,
	// or when an asynchronous response informs us that is has more available data for us to send.
	// In the case of the asynchronous response, we don't want to blindly grab the new data,
	// and shove it onto asyncSocket's write queue.
	// Doing so could negatively affect the memory footprint of the application.
	// Instead, we always ensure that we place no more than READ_CHUNKSIZE bytes onto the write queue.
	// 
	// Note that this does not affect the rate at which the HTTPResponse object may generate data.
	// The HTTPResponse is free to do as it pleases, and this is up to the application's developer.
	// If the memory footprint is a concern, the developer creating the custom HTTPResponse object may freely
	// use the calls to readDataOfLength as an indication to start generating more data.
	// This provides an easy way for the HTTPResponse object to throttle its data allocation in step with the rate
	// at which the socket is able to send it.
	
	NSUInteger writeQueueSize = [self writeQueueSize];
	
	if(writeQueueSize >= READ_CHUNKSIZE) return;
	
	DDRange range = [[ranges objectAtIndex:0] ddrangeValue];
	
	UInt64 offset = [httpResponse offset];
	UInt64 bytesRead = offset - range.location;
	UInt64 bytesLeft = range.length - bytesRead;
	
	if(bytesLeft > 0)
	{
		NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
		NSUInteger bytesToRead = bytesLeft < available ? (NSUInteger)bytesLeft : available;
		
		NSData *data = [httpResponse readDataOfLength:bytesToRead];
		
		if([data length] > 0)
		{
			[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
			
			long tag = [data length] == bytesLeft ? HTTP_RESPONSE : HTTP_PARTIAL_RANGE_RESPONSE_BODY;
			[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:tag];
		}
	}
}

/**
 * Sends more data, if needed, without growing the write queue over its approximate size limit.
 * The last chunk of the response body will be sent with a tag of HTTP_RESPONSE.
 * 
 * This method should only be called for multi-range responses.
**/
- (void)continueSendingMultiRangeResponseBody
{
	// This method is called when either asyncSocket has finished writing one of the response data chunks,
	// or when an asynchronous HTTPResponse object informs us that is has more available data for us to send.
	// In the case of the asynchronous HTTPResponse, we don't want to blindly grab the new data,
	// and shove it onto asyncSocket's write queue.
	// Doing so could negatively affect the memory footprint of the application.
	// Instead, we always ensure that we place no more than READ_CHUNKSIZE bytes onto the write queue.
	// 
	// Note that this does not affect the rate at which the HTTPResponse object may generate data.
	// The HTTPResponse is free to do as it pleases, and this is up to the application's developer.
	// If the memory footprint is a concern, the developer creating the custom HTTPResponse object may freely
	// use the calls to readDataOfLength as an indication to start generating more data.
	// This provides an easy way for the HTTPResponse object to throttle its data allocation in step with the rate
	// at which the socket is able to send it.
	
	NSUInteger writeQueueSize = [self writeQueueSize];
	
	if(writeQueueSize >= READ_CHUNKSIZE) return;
	
	DDRange range = [[ranges objectAtIndex:rangeIndex] ddrangeValue];
	
	UInt64 offset = [httpResponse offset];
	UInt64 bytesRead = offset - range.location;
	UInt64 bytesLeft = range.length - bytesRead;
	
	if(bytesLeft > 0)
	{
		NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
		NSUInteger bytesToRead = bytesLeft < available ? (NSUInteger)bytesLeft : available;
		
		NSData *data = [httpResponse readDataOfLength:bytesToRead];
		
		if([data length] > 0)
		{
			[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
			
			[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:HTTP_PARTIAL_RANGES_RESPONSE_BODY];
		}
	}
	else
	{
		if(++rangeIndex < [ranges count])
		{
			// Write range header
			NSData *rangeHeader = [ranges_headers objectAtIndex:rangeIndex];
			[asyncSocket writeData:rangeHeader withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_PARTIAL_RESPONSE_HEADER];
			
			// Start writing range body
			range = [[ranges objectAtIndex:rangeIndex] ddrangeValue];
			
			[httpResponse setOffset:range.location];
			
			NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
			NSUInteger bytesToRead = range.length < available ? (NSUInteger)range.length : available;
			
			NSData *data = [httpResponse readDataOfLength:bytesToRead];
			
			if([data length] > 0)
			{
				[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
				
				[asyncSocket writeData:data withTimeout:WRITE_BODY_TIMEOUT tag:HTTP_PARTIAL_RANGES_RESPONSE_BODY];
			}
		}
		else
		{
			// We're not done yet - we still have to send the closing boundry tag
			NSString *endingBoundryStr = [NSString stringWithFormat:@"\r\n--%@--\r\n", ranges_boundry];
			NSData *endingBoundryData = [endingBoundryStr dataUsingEncoding:NSUTF8StringEncoding];
			
			[asyncSocket writeData:endingBoundryData withTimeout:WRITE_HEAD_TIMEOUT tag:HTTP_RESPONSE];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Responses
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Converts relative URI path into full file-system path.
**/
- (NSString *)filePathForURI:(NSString *)path
{
	// Override me to perform custom path mapping.
	// For example you may want to use a default file other than index.html, or perhaps support multiple types.
	
	// If there is no configured documentRoot, then it makes no sense to try to return anything
	if(![server documentRoot]) return nil;
	
	// Convert path to a relative path.
	// This essentially means trimming beginning '/' characters.
	// Beware of a bug in the Cocoa framework:
	// 
	// [NSURL URLWithString:@"/foo" relativeToURL:baseURL]       == @"/baseURL/foo"
	// [NSURL URLWithString:@"/foo%20bar" relativeToURL:baseURL] == @"/foo bar"
	// [NSURL URLWithString:@"/foo" relativeToURL:baseURL]       == @"/foo"
	
	NSString *relativePath = path;
	
	while([relativePath hasPrefix:@"/"] && [relativePath length] > 1)
	{
		relativePath = [relativePath substringFromIndex:1];
	}
	
	NSURL *url;
	
	if([relativePath hasSuffix:@"/"])
	{
		NSString *completedRelativePath = [relativePath stringByAppendingString:@"index.html"];
		url = [NSURL URLWithString:completedRelativePath relativeToURL:[server documentRoot]];
	}
	else
	{
		url = [NSURL URLWithString:relativePath relativeToURL:[server documentRoot]];
	}
	
	// Watch out for sneaky requests with ".." in the path
	// For example, the following request: "../Documents/TopSecret.doc"
	if(![[url path] hasPrefix:[[server documentRoot] path]]) return nil;
	
	return [[url path] stringByStandardizingPath];
}

/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResponse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	// Override me to provide custom responses.
	
	NSString *filePath = [self filePathForURI:path];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath] autorelease];
	
	//	// Use me instead for asynchronous file IO
	//	
	//	return [[[HTTPAsyncFileResponse alloc] initWithFilePath:filePath
	//											  forConnection:self
	//											   runLoopModes:[asyncSocket runLoopModes]] autorelease];
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Uploads
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is called after receiving all HTTP headers, but before reading any of the request body.
**/
- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	// Override me to allocate buffers, file handles, etc.
}

/**
 * This method is called to handle data read from a POST / PUT.
 * The given data is part of the request body.
**/
- (void)processDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST / PUT.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Errors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Called if the HTML version is other than what is supported
**/
- (void)handleVersionNotSupported:(NSString *)version
{
	// Override me for custom error handling of unsupported http version responses
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	NSLog(@"HTTP Server: Error 505 - Version Not Supported: %@ (%@)", version, [self requestURI]);
	
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
    
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(response);
}

/**
 * Called if the authentication information was required and absent, or if authentication failed.
**/
- (void)handleAuthenticationFailed
{
	// Override me for custom handling of authentication challenges
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	NSLog(@"HTTP Server: Error 401 - Unauthorized (%@)", [self requestURI]);
		
	// Status Code 401 - Unauthorized
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 401, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
	
	if([self useDigestAccessAuthentication])
	{
		[self addDigestAuthChallenge:response];
	}
	else
	{
		[self addBasicAuthChallenge:response];
	}
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(response);
}

/**
 * Called if we receive some sort of malformed HTTP request.
 * The data parameter is the invalid HTTP header line, including CRLF, as read from AsyncSocket.
 * The data parameter may also be nil if the request as a whole was invalid, such as a POST with no Content-Length.
**/
- (void)handleInvalidRequest:(NSData *)data
{
	// Override me for custom error handling of invalid HTTP requests
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	NSLog(@"HTTP Server: Error 400 - Bad Request (%@)", [self requestURI]);
	
	// Status Code 400 - Bad Request
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Connection"), CFSTR("close"));
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_FINAL_RESPONSE];
	
	CFRelease(response);
	
	// Note: We used the HTTP_FINAL_RESPONSE tag to disconnect after the response is sent.
	// We do this because we couldn't parse the request,
	// so we won't be able to recover and move on to another request afterwards.
	// In other words, we wouldn't know where the first request ends and the second request begins.
}

/**
 * Called if we receive a HTTP request with a method other than GET or HEAD.
**/
- (void)handleUnknownMethod:(NSString *)method
{
	// Override me for custom error handling of 405 method not allowed responses.
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	// 
	// See also: supportsMethod:atPath:
	
	NSLog(@"HTTP Server: Error 405 - Method Not Allowed: %@ (%@)", method, [self requestURI]);
	
	// Status code 405 - Method Not Allowed
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Connection"), CFSTR("close"));
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_FINAL_RESPONSE];
    
	CFRelease(response);
	
	// Note: We used the HTTP_FINAL_RESPONSE tag to disconnect after the response is sent.
	// We do this because the method may include an http body.
	// Since we can't be sure, we should close the connection.
}

/**
 * Called if we're unable to find the requested resource.
**/
- (void)handleResourceNotFound
{
	// Override me for custom error handling of 404 not found responses
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	NSLog(@"HTTP Server: Error 404 - Not Found (%@)", [self requestURI]);
	
	// Status Code 404 - Not Found
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), CFSTR("0"));
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:WRITE_ERROR_TIMEOUT tag:HTTP_RESPONSE];
	
	CFRelease(response);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Headers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Gets the current date and time, formatted properly (according to RFC) for insertion into an HTTP header.
**/
- (NSString *)dateAsString:(NSDate *)date
{
	// Example: Sun, 06 Nov 1994 08:49:37 GMT
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	[df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
	[df setDateFormat:@"EEE, dd MMM y HH:mm:ss 'GMT'"];
	
	// For some reason, using zzz in the format string produces GMT+00:00
	
	return [df stringFromDate:date];
}

/**
 * This method is called immediately prior to sending the response headers.
 * This method adds standard header fields, and then converts the response to an NSData object.
**/
- (NSData *)preprocessResponse:(CFHTTPMessageRef)response
{
	// Override me to customize the response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessResponse:response]
	
	// Add standard headers
	NSString *now = [self dateAsString:[NSDate date]];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Date"), (CFStringRef)now);
	
	// Add server capability headers
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Accept-Ranges"), CFSTR("bytes"));
	
	// Add optional response headers
	if([httpResponse respondsToSelector:@selector(httpHeaders)])
	{
		NSDictionary *responseHeaders = [httpResponse httpHeaders];
		
		NSEnumerator *keyEnumerator = [responseHeaders keyEnumerator];
		NSString *key;
		
		while((key = [keyEnumerator nextObject]))
		{
			NSString *value = [responseHeaders objectForKey:key];
			
			CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)key, (CFStringRef)value);
		}
	}
	
	NSData *result = NSMakeCollectable(CFHTTPMessageCopySerializedMessage(response));
	return [result autorelease];
}

/**
 * This method is called immediately prior to sending the response headers (for an error).
 * This method adds standard header fields, and then converts the response to an NSData object.
**/
- (NSData *)preprocessErrorResponse:(CFHTTPMessageRef)response;
{
	// Override me to customize the error response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessErrorResponse:response]
	// 
	// Notes:
	// You can use CFHTTPMessageGetResponseStatusCode(response) to get the type of error.
	// You can use CFHTTPMessageSetBody() to add an optional HTML body.
	// If you add a body, don't forget to update the Content-Length.
	// 
	// if(CFHTTPMessageGetResponseStatusCode(response) == 404)
	// {
	//     NSString *msg = @"<html><body>Error 404 - Not Found</body></html>";
	//     NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	//     
	//     CFHTTPMessageSetBody(response, (CFDataRef)msgData);
	//     
	//     NSString *contentLengthStr = [NSString stringWithFormat:@"%lu", (unsigned long)[msgData length]];
	//     CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Content-Length"), (CFStringRef)contentLengthStr);
	// }
	
	// Add standard headers
	NSString *now = [self dateAsString:[NSDate date]];
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Date"), (CFStringRef)now);
	
	// Add server capability headers
	CFHTTPMessageSetHeaderFieldValue(response, CFSTR("Accept-Ranges"), CFSTR("bytes"));
	
	// Add optional response headers
	if([httpResponse respondsToSelector:@selector(httpHeaders)])
	{
		NSDictionary *responseHeaders = [httpResponse httpHeaders];
		
		NSEnumerator *keyEnumerator = [responseHeaders keyEnumerator];
		NSString *key;
		
		while((key = [keyEnumerator nextObject]))
		{
			NSString *value = [responseHeaders objectForKey:key];
			
			CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)key, (CFStringRef)value);
		}
	}
	
	NSData *result = NSMakeCollectable(CFHTTPMessageCopySerializedMessage(response));
	return [result autorelease];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark AsyncSocket Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is called immediately prior to opening up the stream.
 * This is the time to manually configure the stream if necessary.
**/
- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
	if([self isSecureServer])
	{
		// We are configured to be an HTTPS server.
		// That is, we secure via SSL/TLS the connection prior to any communication.
		
		NSArray *certificates = [self sslIdentityAndCertificates];
		
		if([certificates count] > 0)
		{
			// All connections are assumed to be secure. Only secure connections are allowed on this server.
			NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
			
			// Configure this connection as the server
			[settings setObject:[NSNumber numberWithBool:YES]
						 forKey:(NSString *)kCFStreamSSLIsServer];
			
			[settings setObject:certificates
						 forKey:(NSString *)kCFStreamSSLCertificates];
			
			// Configure this connection to use the highest possible SSL level
			[settings setObject:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
						 forKey:(NSString *)kCFStreamSSLLevel];
			
			[asyncSocket startTLS:settings];
		}
	}
	return YES;
}

/**
 * This method is called after the socket has been fully opened.
 * It is called on the proper thread/runloop that HTTPServer configured our socket to run on.
**/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	// The socket is up and ready, and this method is called on the socket's corresponding thread.
	// We can now start reading the HTTP requests...
	[asyncSocket readDataToData:[AsyncSocket CRLFData]
					withTimeout:READ_TIMEOUT
					  maxLength:LIMIT_MAX_HEADER_LINE_LENGTH
							tag:HTTP_REQUEST_HEADER];
}

/**
 * This method is called after the socket has successfully read data from the stream.
 * Remember that this method will only be called after the socket reaches a CRLF, or after it's read the proper length.
**/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	if(tag == HTTP_REQUEST_HEADER)
	{
		// Append the header line to the http message
		BOOL result = CFHTTPMessageAppendBytes(request, [data bytes], [data length]);
		if(!result)
		{
			// We have a received a malformed request
			[self handleInvalidRequest:data];
		}
		else if(!CFHTTPMessageIsHeaderComplete(request))
		{
			// We don't have a complete header yet
			// That is, we haven't yet received a CRLF on a line by itself, indicating the end of the header
			if(++numHeaderLines > LIMIT_MAX_HEADER_LINES)
			{
				// Reached the maximum amount of header lines in a single HTTP request
				// This could be an attempted DOS attack
				[asyncSocket disconnect];
				
				// Explictly return to ensure we don't do anything after the socket disconnect
				return;
			}
			else
			{
				[asyncSocket readDataToData:[AsyncSocket CRLFData]
								withTimeout:READ_TIMEOUT
								  maxLength:LIMIT_MAX_HEADER_LINE_LENGTH
										tag:HTTP_REQUEST_HEADER];
			}
		}
		else
		{
			// We have an entire HTTP request header from the client
			
			// Extract the method (such as GET, HEAD, POST, etc)
			NSString *method = [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(request)) autorelease];
			
			// Extract the uri (such as "/index.html")
			NSString *uri = [self requestURI];
			
			// Check for a Content-Length field
			NSString *contentLength =
			    [NSMakeCollectable(CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Content-Length"))) autorelease];
			
			// Content-Length MUST be present for upload methods (such as POST or PUT)
			// and MUST NOT be present for other methods.
			BOOL expectsUpload = [self expectsRequestBodyFromMethod:method atPath:uri];
			
			if(expectsUpload)
			{
				if(contentLength == nil)
				{
					// Method expects request body, but request had no specified Content-Length
					[self handleInvalidRequest:nil];
					return;
				}
				
				if(![NSNumber parseString:(NSString *)contentLength intoUInt64:&requestContentLength])
				{
					// Unable to parse Content-Length header into a valid number
					[self handleInvalidRequest:nil];
					return;
				}
			}
			else
			{
				if(contentLength != nil)
				{
					// Received Content-Length header for method not expecting an upload.
					// This better be zero...
					
					if(![NSNumber parseString:(NSString *)contentLength intoUInt64:&requestContentLength])
					{
						// Unable to parse Content-Length header into a valid number
						[self handleInvalidRequest:nil];
						return;
					}
					
					if(requestContentLength > 0)
					{
						[self handleInvalidRequest:nil];
						return;
					}
				}
				
				requestContentLength = 0;
				requestContentLengthReceived = 0;
			}
			
			// Check to make sure the given method is supported
			if(![self supportsMethod:method atPath:uri])
			{
				// The method is unsupported - either in general, or for this specific request
				// Send a 405 - Method not allowed response
				[self handleUnknownMethod:method];
				return;
			}
			
			if(expectsUpload)
			{
				// Reset the total amount of data received for the upload
				requestContentLengthReceived = 0;
				
				// Prepare for the upload
				[self prepareForBodyWithSize:requestContentLength];
				
				// Start reading the request body
				NSUInteger bytesToRead;
				if(requestContentLength < POST_CHUNKSIZE)
					bytesToRead = (NSUInteger)requestContentLength;
				else
					bytesToRead = POST_CHUNKSIZE;
				
				[asyncSocket readDataToLength:bytesToRead withTimeout:READ_TIMEOUT tag:HTTP_REQUEST_BODY];
			}
			else
			{
				// Now we need to reply to the request
				[self replyToHTTPRequest];
			}
		}
	}
	else
	{
		// Handle a chunk of data from the POST body
		
		requestContentLengthReceived += [data length];
		[self processDataChunk:data];
		
		if(requestContentLengthReceived < requestContentLength)
		{
			// We're not done reading the post body yet...
			UInt64 bytesLeft = requestContentLength - requestContentLengthReceived;
			
			NSUInteger bytesToRead = bytesLeft < POST_CHUNKSIZE ? (NSUInteger)bytesLeft : POST_CHUNKSIZE;
			
			[asyncSocket readDataToLength:bytesToRead withTimeout:READ_TIMEOUT tag:HTTP_REQUEST_BODY];
		}
		else
		{
			// Now we need to reply to the request
			[self replyToHTTPRequest];
		}
	}
}

/**
 * This method is called after the socket has successfully written data to the stream.
**/
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	BOOL doneSendingResponse = NO;
	
	if(tag == HTTP_PARTIAL_RESPONSE_BODY)
	{
		// Update the amount of data we have in asyncSocket's write queue
		[responseDataSizes removeObjectAtIndex:0];
		
		// We only wrote a part of the response - there may be more
		[self continueSendingStandardResponseBody];
	}
	else if(tag == HTTP_CHUNKED_RESPONSE_BODY)
	{
		// Update the amount of data we have in asyncSocket's write queue.
		// This will allow asynchronous responses to continue sending more data.
		[responseDataSizes removeObjectAtIndex:0];
		
		// Don't continue sending the response yet.
		// The chunked footer that was sent after the body will tell us if we have more data to send.
	}
	else if(tag == HTTP_CHUNKED_RESPONSE_FOOTER)
	{
		// Normal chunked footer indicating we have more data to send (non final footer).
		[self continueSendingStandardResponseBody];
	}
	else if(tag == HTTP_PARTIAL_RANGE_RESPONSE_BODY)
	{
		// Update the amount of data we have in asyncSocket's write queue
		[responseDataSizes removeObjectAtIndex:0];
		
		// We only wrote a part of the range - there may be more
		[self continueSendingSingleRangeResponseBody];
	}
	else if(tag == HTTP_PARTIAL_RANGES_RESPONSE_BODY)
	{
		// Update the amount of data we have in asyncSocket's write queue
		[responseDataSizes removeObjectAtIndex:0];
		
		// We only wrote part of the range - there may be more, or there may be more ranges
		[self continueSendingMultiRangeResponseBody];
	}
	else if(tag == HTTP_RESPONSE || tag == HTTP_FINAL_RESPONSE)
	{
		// Update the amount of data we have in asyncSocket's write queue
		if([responseDataSizes count] > 0)
		{
			[responseDataSizes removeObjectAtIndex:0];
		}
		
		doneSendingResponse = YES;
	}
	
	if(doneSendingResponse)
	{
		if(tag == HTTP_FINAL_RESPONSE)
		{
			// Terminate the connection
			[asyncSocket disconnect];
			
			// Explictly return to ensure we don't do anything after the socket disconnect
			return;
		}
		else
		{
			// Cleanup after the last request
			// And start listening for the next request
			
			// Inform the http response that we're done
			if([httpResponse respondsToSelector:@selector(connectionDidClose)])
			{
				[httpResponse connectionDidClose];
			}
			
			// Release any resources we no longer need
			[httpResponse release];
			httpResponse = nil;
			
			[ranges release];
			[ranges_headers release];
			[ranges_boundry release];
			ranges = nil;
			ranges_headers = nil;
			ranges_boundry = nil;
			
			if([self shouldDie])
			{
				[self die];
			}
			else
			{
				// Release the old request, and create a new one
				if(request) CFRelease(request);
				request = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
				
				numHeaderLines = 0;
				
				// And start listening for more requests
				[asyncSocket readDataToData:[AsyncSocket CRLFData]
								withTimeout:READ_TIMEOUT
								  maxLength:LIMIT_MAX_HEADER_LINE_LENGTH
										tag:HTTP_REQUEST_HEADER];
			}
		}
	}
}

/**
 * This message is sent:
 *  - if there is an connection, time out, or other i/o error.
 *  - if the remote socket cleanly disconnects.
 *  - before the local socket is disconnected.
**/
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
//	NSLog(@"HTTPConnection: onSocket:willDisconnectWithError: %@", err);
}

/**
 * Sent after the socket has been disconnected.
**/
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	[self die];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark HTTPResponse Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method may be called by asynchronous HTTPResponse objects.
 * That is, HTTPResponse objects that return YES in their "- (BOOL)isAsynchronous" method.
 * 
 * This informs us that the response object has generated more data that we may be able to send.
**/
- (void)responseHasAvailableData
{
	if(ranges == nil)
	{
		[self continueSendingStandardResponseBody];
	}
	else
	{
		if([ranges count] == 1)
			[self continueSendingSingleRangeResponseBody];
		else
			[self continueSendingMultiRangeResponseBody];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Closing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)shouldDie
{
	// Override me if you want to force close the connection after the response has been fully sent.
	
	return NO;
}

- (void)die
{
	// Override me if you want to perform any custom actions when a connection is closed.
	// Then call [super die] when you're done.
	
	// Inform the http response that we're done
	if([httpResponse respondsToSelector:@selector(connectionDidClose)])
	{
		[httpResponse connectionDidClose];
	}
	
	// Release the http response so we don't call it's connectionDidClose method again in our dealloc method
	[httpResponse release];
	httpResponse = nil;
	
	// Post notification of dead connection
	// This will allow our server to release us from its array of connections
	[[NSNotificationCenter defaultCenter] postNotificationName:HTTPConnectionDidDieNotification object:self];
}

@end

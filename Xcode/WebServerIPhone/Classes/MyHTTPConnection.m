#import "MyHTTPConnection.h"
#import "MyHTTPServer.h"
#import "WebServerIPhoneAppDelegate.h"
#import "HTTPResponse.h"
#import "HTTPDynamicFileResponse.h"
#import "DDLog.h"
#import "DDFileLogger.h"
#import "WebSocketLogger.h"


@implementation MyHTTPConnection

- (MyHTTPServer *)myHttpServer
{
	return (MyHTTPServer *)server;
}

- (id <DDLogFileManager>)logFileManager
{
	WebServerIPhoneAppDelegate *appDelegate;
	appDelegate = (WebServerIPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	return appDelegate.fileLogger.logFileManager;
}

- (NSData *)generateIndexData
{
	NSArray *sortedLogFileInfos = [[self logFileManager] sortedLogFileInfos];
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	[df setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	
	NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterDecimalStyle];
	[nf setMinimumFractionDigits:2];
	[nf setMaximumFractionDigits:2];
	
	NSMutableString *response = [NSMutableString stringWithCapacity:1000];
	
	[response appendString:@"<html><head>"];
	[response appendString:@"<style type='text/css'>@import url('styles.css');</style>"];
	[response appendString:@"</head><body>"];
	
	[response appendString:@"<h1>Device Log Files</h1>"];
	
	[response appendString:@"<table cellspacing='2'>"];
	
	for (DDLogFileInfo *logFileInfo in sortedLogFileInfos)
	{
		NSString *fileName = logFileInfo.fileName;
		NSString *fileDate = [df stringFromDate:[logFileInfo creationDate]];
		NSString *fileSize;
		
		unsigned long long sizeInBytes = logFileInfo.fileSize;
		
		double GBs = (double)(sizeInBytes) / (double)(1024 * 1024 * 1024);
		double MBs = (double)(sizeInBytes) / (double)(1024 * 1024);
		double KBs = (double)(sizeInBytes) / (double)(1024);
		
		if(GBs >= 1.0)
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:GBs]];
			fileSize = [NSString stringWithFormat:@"%@ GB", temp];
		}
		else if(MBs >= 1.0)
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:MBs]];
			fileSize = [NSString stringWithFormat:@"%@ MB", temp];
		}
		else
		{
			NSString *temp = [nf stringFromNumber:[NSNumber numberWithDouble:KBs]];
			fileSize = [NSString stringWithFormat:@"%@ KB", temp];
		}
		
		NSString *fileLink = [NSString stringWithFormat:@"<a href='/logs/%@'>%@</a>", fileName, fileName];
		
		[response appendFormat:@"<tr><td>%@</td><td>%@</td><td align='right'>%@</td>", fileLink, fileDate, fileSize];
	}
	
	[response appendString:@"</table></body></html>"];
	
	return [response dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)filePathForURI:(NSString *)path
{
	if ([path hasPrefix:@"/logs/"])
	{
		NSString *logsDir = [[self logFileManager] logsDirectory];
		return [logsDir stringByAppendingPathComponent:[path lastPathComponent]];
	}
	
	return [super filePathForURI:path];
}

- (NSString *)wsLocation
{
	NSString *port = [NSString stringWithFormat:@"%hu", [server port]];
	
	NSString *wsLocation;
	NSString *wsHost = NSMakeCollectable(CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Host")));
	
	if (wsHost == nil)
	{
		wsLocation = [NSString stringWithFormat:@"ws://localhost:%@/livelog", port];
	}
	else
	{
		wsLocation = [NSString stringWithFormat:@"ws://%@/livelog", wsHost];
	}
	
	[wsHost release];
	return wsLocation;
}

- (NSString *)wsOrigin
{
	NSString *port = [NSString stringWithFormat:@"%hu", [server port]];
	
	NSString *wsOrigin = NSMakeCollectable(CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Origin")));
	
	if (wsOrigin == nil)
	{
		return [NSString stringWithFormat:@"http://localhost:%@", port];
	}
	else {
		return [wsOrigin autorelease];
	}
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	if ([path isEqualToString:@"/logs.html"])
	{
		NSData *indexData = [self generateIndexData];
		return [[[HTTPDataResponse alloc] initWithData:indexData] autorelease];
	}
	else if ([path isEqualToString:@"/socket.html"])
	{
		// The socket.html file contains a URL template that needs to be completed:
		// 
		// ws = new WebSocket("%%WEBSOCKET_URL%%");
		// 
		// We need to replace "%%WEBSOCKET_URL%%" with whatever URL the server is running on.
		// We can accomplish this easily with the HTTPDynamicFileResponse class,
		// which takes a dictionary of replacement key-value pairs,
		// and performs replacements on the fly as it uploads the file.
		
		NSString *loc = [self wsLocation];
		NSDictionary *replacementDict = [NSDictionary dictionaryWithObject:loc forKey:@"WEBSOCKET_URL"];
		
		return [[[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
													forConnection:self
													 runLoopModes:[asyncSocket runLoopModes]
														separator:@"%%"
											replacementDictionary:replacementDict] autorelease];
	}
	else if ([path isEqualToString:@"/livelog"])
	{
		// Request:
		// 
		// GET /service HTTP/1.1
		// Upgrade: WebSocket
		// Connection: Upgrade
		// Host: localhost:12345
		// Origin: http://localhost:12345
		
		isWebSocketRequest = YES;
		
		// Return an empty response.
		// This will let the HTTPConnection handle most of the normal HTTP response stuff.
		return [[[HTTPDataResponse alloc] initWithData:nil] autorelease];
	}
	else
	{
		return [super httpResponseForMethod:method URI:path];
	}
}

- (NSData *)preprocessResponse:(CFHTTPMessageRef)response
{
	if(isWebSocketRequest)
	{
		// Response:
		// 
		// HTTP/1.1 101 Web Socket Protocol Handshake
		// Upgrade: WebSocket
		// Connection: Upgrade
		// WebSocket-Origin: http://localhost:12345
		// WebSocket-Location: ws://localhost:12345/livelog
		
		CFHTTPMessageRef wsResponse = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
		                                                          101, CFSTR("Web Socket Protocol Handshake"),
		                                                          kCFHTTPVersion1_1);
		
		CFHTTPMessageSetHeaderFieldValue(wsResponse, CFSTR("Upgrade"), CFSTR("WebSocket"));
		CFHTTPMessageSetHeaderFieldValue(wsResponse, CFSTR("Connection"), CFSTR("Upgrade"));
		
		// Note: It appears that WebSocket-Origin and WebSocket-Location
		// are required for Google's Chrome implementation to work properly.
		// 
		// If we don't send either header, Chrome will never report the WebSocket as open.
		// If we only send one of the two, Chrome will immediately close the WebSocket.
		// 
		// In addition to this it appears that Chrome's implementation is very picky of the values of the headers.
		// They have to match exactly with what Chrome sent us or it will close the WebSocket.

		NSString *wsLocation = [self wsLocation];
		NSString *wsOrigin = [self wsOrigin];
		
		CFHTTPMessageSetHeaderFieldValue(wsResponse, CFSTR("WebSocket-Origin"), (CFStringRef)wsOrigin);
		CFHTTPMessageSetHeaderFieldValue(wsResponse, CFSTR("WebSocket-Location"), (CFStringRef)wsLocation);
						  
		// Do not invoke super.
		// The above headers are all that is required for a WebSocket.
		
		NSData *result = NSMakeCollectable(CFHTTPMessageCopySerializedMessage(wsResponse));
		
		NSString *tempStr = [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"WebSocket Response:\n%@", tempStr);
		
		return [result autorelease];
	}
	else
	{
		return [super preprocessResponse:response];
	}
}

- (BOOL)shouldDie
{
	if (isWebSocketRequest)
	{
		// Create our web socket
		WebSocketLogger *ws = [[[WebSocketLogger alloc] initWithSocket:asyncSocket] autorelease];
		
		// Add the web socket to the server's list (so that it's retained somewhere)
		[[self myHttpServer] addWebSocket:ws];
		
		// The WebSocket now has ownership of the underlying socket.
		// So remove the HTTPConnection's reference to it.
		[asyncSocket release];
		asyncSocket = nil;
		
		return YES;
	}
	else
	{
		return [super shouldDie];
	}
}

@end
